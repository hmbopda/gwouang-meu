#!/usr/bin/env bash
#
# harden-cloudflare.sh — durcit la sécurité de la zone gwouangmeu.com.
#
# Applique via l'API Cloudflare les réglages de protection recommandés :
#   • SSL/TLS en Full (Strict), HTTPS forcé, réécriture auto, TLS 1.2 mini, TLS 1.3
#   • HSTS (HTTP Strict Transport Security)
#   • DNSSEC activé (anti-usurpation DNS) — automatique car domaine Cloudflare
#   • Niveau de sécurité "medium"
#
# Les enregistrements anti-usurpation d'email (SPF/DMARC) sont posés par
# setup-cloudflare-dns.sh à partir de config.env.
#
# Pré-requis : bash, curl, jq, et un API Token (mêmes permissions que le
# script DNS + "Zone Settings:Edit" et "DNSSEC:Edit").
#
# Usage :  ./harden-cloudflare.sh
#
set -euo pipefail
cd "$(dirname "$0")"
CONFIG="${1:-config.env}"
[[ -f "$CONFIG" ]] || { echo "✗ config introuvable ($CONFIG). cp config.example.env config.env"; exit 1; }
# shellcheck disable=SC1090
source "$CONFIG"
command -v jq >/dev/null || { echo "✗ 'jq' requis"; exit 1; }

API="https://api.cloudflare.com/client/v4"
AUTH=(-H "Authorization: Bearer ${CF_API_TOKEN}" -H "Content-Type: application/json")

cf() { # method path [json-body]
  if [[ -n "${3:-}" ]]; then
    curl -fsS -X "$1" "${API}${2}" "${AUTH[@]}" --data "$3"
  else
    curl -fsS -X "$1" "${API}${2}" "${AUTH[@]}"
  fi
}

ZID=$(cf GET "/zones?name=${CANONICAL_DOMAIN}&status=active" | jq -r '.result[0].id // empty')
[[ -n "$ZID" ]] || { echo "✗ Zone '${CANONICAL_DOMAIN}' introuvable/inactive."; exit 1; }
echo "▶ Durcissement de ${CANONICAL_DOMAIN} (zone ${ZID})"

# setting <nom> <valeur-json>
setting() {
  local name="$1" value="$2"
  if cf PATCH "/zones/${ZID}/settings/${name}" "{\"value\":${value}}" >/dev/null 2>&1; then
    echo "   ✓ ${name} = ${value}"
  else
    echo "   ⚠ ${name} : non appliqué (plan insuffisant ou réglage indisponible) — à vérifier au dashboard"
  fi
}

setting ssl                     '"strict"'     # Full (Strict) : chiffré de bout en bout
setting always_use_https        '"on"'         # redirige tout HTTP → HTTPS
setting automatic_https_rewrites '"on"'        # réécrit les liens http:// en https://
setting min_tls_version         '"1.2"'        # refuse TLS 1.0/1.1 obsolètes
setting tls_1_3                  '"on"'
setting opportunistic_encryption '"on"'
setting brotli                  '"on"'
setting security_level          '"medium"'

# HSTS : force HTTPS côté navigateur pendant 1 an (preload à activer plus tard,
# seulement quand tu es sûr que tout est en HTTPS — c'est difficilement réversible).
setting security_header '{
  "strict_transport_security": {
    "enabled": true,
    "max_age": 31536000,
    "include_subdomains": true,
    "preload": false,
    "nosniff": true
  }
}'

# DNSSEC : signe cryptographiquement la zone (anti-empoisonnement DNS).
# Domaine enregistré chez Cloudflare → activation de bout en bout automatique.
if cf PATCH "/zones/${ZID}/dnssec" '{"status":"active"}' >/dev/null 2>&1; then
  echo "   ✓ DNSSEC = active"
else
  echo "   ⚠ DNSSEC : à activer au dashboard (DNS → Settings → DNSSEC)"
fi

echo "✅ Durcissement appliqué."
echo
echo "À COCHER À LA MAIN dans le dashboard (non exposés par l'API sur le plan gratuit) :"
echo "   • Registrar → Auto-renew : ON (que le domaine n'expire jamais)"
echo "   • Registrar → Domain Lock (clientTransferProhibited) : ON (souvent déjà par défaut)"
echo "   • Registrar → WHOIS redaction : ON (confidentialité — gratuit chez Cloudflare)"
echo "   • Security → Bots → Bot Fight Mode : ON (gratuit)"
echo "   • (Plus tard) SSL/TLS → HSTS → Preload : ON, une fois 100% en HTTPS"
