#!/usr/bin/env bash
#
# setup-cloudflare-dns.sh — configure le DNS multi-domaines de GWOUANG MEU.
#
#   1. Crée les enregistrements DNS du domaine canonique (landing, app, api,
#      staging-api, media, SPF/DKIM/DMARC).
#   2. Pose une redirection 301 (racine + www) des domaines secondaires vers
#      le canonique, via un ruleset "dynamic redirect" par zone.
#
# Idempotent : relançable sans créer de doublons (les records existants sont
# mis à jour, pas dupliqués).
#
# Pré-requis : bash, curl, jq. Les zones doivent déjà exister dans Cloudflare
# (domaine enregistré chez Cloudflare, ou ajouté via "Add a site").
#
# Usage :
#   cp config.example.env config.env && $EDITOR config.env
#   ./setup-cloudflare-dns.sh
#
set -euo pipefail

cd "$(dirname "$0")"
CONFIG="${1:-config.env}"
if [[ ! -f "$CONFIG" ]]; then
  echo "✗ Fichier de config introuvable : $CONFIG"
  echo "  Fais : cp config.example.env config.env  puis édite-le."
  exit 1
fi
# shellcheck disable=SC1090
source "$CONFIG"

command -v jq >/dev/null || { echo "✗ 'jq' est requis (apt install jq / brew install jq)"; exit 1; }

API="https://api.cloudflare.com/client/v4"
AUTH=(-H "Authorization: Bearer ${CF_API_TOKEN}" -H "Content-Type: application/json")

# ── helpers ─────────────────────────────────────────────────────────────────

cf() { # method path [json-body]
  local method="$1" path="$2" body="${3:-}"
  if [[ -n "$body" ]]; then
    curl -fsS -X "$method" "${API}${path}" "${AUTH[@]}" --data "$body"
  else
    curl -fsS -X "$method" "${API}${path}" "${AUTH[@]}"
  fi
}

zone_id() { # domain -> id (vide si absente)
  cf GET "/zones?name=$1&status=active" | jq -r '.result[0].id // empty'
}

# upsert_record zone_id type name content proxied
upsert_record() {
  local zid="$1" type="$2" name="$3" content="$4" proxied="${5:-false}"
  local existing
  existing=$(cf GET "/zones/${zid}/dns_records?type=${type}&name=${name}" \
             | jq -r '.result[0].id // empty')
  local payload
  payload=$(jq -nc --arg t "$type" --arg n "$name" --arg c "$content" \
               --argjson p "$proxied" \
               '{type:$t,name:$n,content:$c,proxied:$p,ttl:1}')
  if [[ -n "$existing" ]]; then
    cf PUT "/zones/${zid}/dns_records/${existing}" "$payload" >/dev/null
    echo "   ↻ $type $name → $content"
  else
    cf POST "/zones/${zid}/dns_records" "$payload" >/dev/null
    echo "   ✓ $type $name → $content"
  fi
}

# upsert_txt zone_id name value  (les TXT sont matchés par nom ; on remplace le 1er)
upsert_txt() {
  local zid="$1" name="$2" value="$3"
  local existing
  existing=$(cf GET "/zones/${zid}/dns_records?type=TXT&name=${name}" \
             | jq -r '.result[0].id // empty')
  local payload
  payload=$(jq -nc --arg n "$name" --arg c "$value" \
               '{type:"TXT",name:$n,content:$c,ttl:1}')
  if [[ -n "$existing" ]]; then
    cf PUT "/zones/${zid}/dns_records/${existing}" "$payload" >/dev/null
    echo "   ↻ TXT $name"
  else
    cf POST "/zones/${zid}/dns_records" "$payload" >/dev/null
    echo "   ✓ TXT $name"
  fi
}

# redirect_zone zone_id from_domain to_domain
# Remplace l'entrypoint du ruleset http_request_dynamic_redirect de la zone
# par une règle unique : tout host de la zone → https://<canonical>/<path>.
redirect_zone() {
  local zid="$1" from="$2" to="$3"
  local rule
  rule=$(jq -nc --arg to "$to" '
    {
      rules: [{
        action: "redirect",
        action_parameters: {
          from_value: {
            status_code: 301,
            target_url: { expression: ("concat(\"https://" + $to + "\", http.request.uri.path)") },
            preserve_query_string: true
          }
        },
        expression: "true",
        description: ("Redirection 301 vers " + $to),
        enabled: true
      }]
    }')
  cf PUT "/zones/${zid}/rulesets/phases/http_request_dynamic_redirect/entrypoint" "$rule" >/dev/null
  echo "   ✓ 301  ${from}  →  ${to}"
}

# ── 1. Domaine canonique ─────────────────────────────────────────────────────

echo "▶ Domaine canonique : ${CANONICAL_DOMAIN}"
CID=$(zone_id "$CANONICAL_DOMAIN")
if [[ -z "$CID" ]]; then
  echo "   ✗ Zone '${CANONICAL_DOMAIN}' absente ou inactive dans Cloudflare."
  echo "     Enregistre le domaine ou ajoute-le (Add a site) puis relance."
  exit 1
fi

upsert_record "$CID" A     "${CANONICAL_DOMAIN}"             "$VERCEL_APEX_IP"          false
upsert_record "$CID" CNAME "www.${CANONICAL_DOMAIN}"        "$VERCEL_CNAME"            false
upsert_record "$CID" CNAME "app.${CANONICAL_DOMAIN}"        "$PAGES_TARGET"            true
upsert_record "$CID" CNAME "api.${CANONICAL_DOMAIN}"        "$RAILWAY_API_TARGET"      false
upsert_record "$CID" CNAME "staging-api.${CANONICAL_DOMAIN}" "$RAILWAY_STAGING_TARGET" false

upsert_txt "$CID" "${CANONICAL_DOMAIN}"                 "$SPF_RECORD"
upsert_txt "$CID" "_dmarc.${CANONICAL_DOMAIN}"         "$DMARC_RECORD"
if [[ -n "${RESEND_DKIM_VALUE:-}" && "$RESEND_DKIM_VALUE" != *colle_ici* ]]; then
  upsert_txt "$CID" "${RESEND_DKIM_NAME}.${CANONICAL_DOMAIN}" "$RESEND_DKIM_VALUE"
else
  echo "   ⏭ DKIM ignoré (aucune valeur — normal tant que tu n'envoies pas d'emails)"
fi

echo "   ℹ  media.${CANONICAL_DOMAIN} : à connecter via R2 → Custom Domains (record auto)."
echo "   ℹ  Email entrant : active Cloudflare Email Routing (crée les MX pour toi)."

# ── 2. Redirections 301 des domaines secondaires ────────────────────────────

echo "▶ Redirections vers ${CANONICAL_DOMAIN}"
for d in ${REDIRECT_DOMAINS:-}; do
  RID=$(zone_id "$d")
  if [[ -z "$RID" ]]; then
    echo "   ⚠ Zone '${d}' absente — ignorée (ajoute-la dans Cloudflare puis relance)."
    continue
  fi
  # Record minimal pour que le proxy Cloudflare intercepte et redirige.
  upsert_record "$RID" A     "$d"       "192.0.2.1" true   # IP de doc RFC5737, jamais atteinte
  upsert_record "$RID" CNAME "www.$d"   "$d"        true
  redirect_zone "$RID" "$d" "$CANONICAL_DOMAIN"
done

echo "✅ Terminé."
