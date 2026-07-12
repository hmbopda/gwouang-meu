# cloudflare.tf — équivalent Terraform du script setup-cloudflare-dns.sh (optionnel).
#
# ⚠️ VERSION DU PROVIDER : ce fichier cible le provider Cloudflare **v4**
#    (ressource `cloudflare_record`). Le provider **v5** a renommé la ressource
#    en `cloudflare_dns_record` et modifié la syntaxe des rulesets. Si tu es en
#    v5, adapte les noms de ressources ou épingle la v4 comme ci-dessous.
#
# Pré-requis : les zones existent déjà dans Cloudflare (domaine enregistré ou
# ajouté via "Add a site"). On ne crée ici que les enregistrements + redirections.

terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.40"
    }
  }
}

provider "cloudflare" {
  api_token = var.cf_api_token
}

# ── Lookups de zones ─────────────────────────────────────────────────────────
data "cloudflare_zone" "canonical" {
  name = var.canonical_domain
}

data "cloudflare_zone" "redirects" {
  for_each = toset(var.redirect_domains)
  name     = each.value
}

# ── Enregistrements du domaine canonique ─────────────────────────────────────
resource "cloudflare_record" "apex" {
  zone_id = data.cloudflare_zone.canonical.id
  name    = "@"
  type    = "A"
  content = var.vercel_apex_ip
  proxied = false
  ttl     = 1
}

resource "cloudflare_record" "www" {
  zone_id = data.cloudflare_zone.canonical.id
  name    = "www"
  type    = "CNAME"
  content = var.vercel_cname
  proxied = false
  ttl     = 1
}

resource "cloudflare_record" "app" {
  zone_id = data.cloudflare_zone.canonical.id
  name    = "app"
  type    = "CNAME"
  content = var.pages_target
  proxied = true
  ttl     = 1
}

resource "cloudflare_record" "api" {
  zone_id = data.cloudflare_zone.canonical.id
  name    = "api"
  type    = "CNAME"
  content = var.railway_api_target
  proxied = false
  ttl     = 1
}

resource "cloudflare_record" "staging_api" {
  zone_id = data.cloudflare_zone.canonical.id
  name    = "staging-api"
  type    = "CNAME"
  content = var.railway_staging_target
  proxied = false
  ttl     = 1
}

resource "cloudflare_record" "spf" {
  zone_id = data.cloudflare_zone.canonical.id
  name    = "@"
  type    = "TXT"
  content = var.spf_record
  ttl     = 1
}

resource "cloudflare_record" "dmarc" {
  zone_id = data.cloudflare_zone.canonical.id
  name    = "_dmarc"
  type    = "TXT"
  content = var.dmarc_record
  ttl     = 1
}

# ── Redirections 301 des domaines secondaires ────────────────────────────────
resource "cloudflare_ruleset" "redirect" {
  for_each = data.cloudflare_zone.redirects

  zone_id = each.value.id
  name    = "Redirection vers ${var.canonical_domain}"
  kind    = "zone"
  phase   = "http_request_dynamic_redirect"

  rules {
    action = "redirect"
    action_parameters {
      from_value {
        status_code = 301
        target_url {
          expression = "concat(\"https://${var.canonical_domain}\", http.request.uri.path)"
        }
        preserve_query_string = true
      }
    }
    expression  = "true"
    description = "301 ${each.key} -> ${var.canonical_domain}"
    enabled     = true
  }
}
