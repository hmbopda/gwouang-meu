variable "cf_api_token" {
  description = "API Token Cloudflare (Zone:Read, DNS:Edit, Dynamic Redirect:Edit)"
  type        = string
  sensitive   = true
}

variable "canonical_domain" {
  description = "Domaine canonique servant l'application"
  type        = string
  default     = "gwouangmeu.com"
}

variable "redirect_domains" {
  description = "Domaines qui redirigent (301) vers le canonique (vide tant qu'il n'y a que le .com)"
  type        = list(string)
  default     = []
}

variable "vercel_apex_ip" {
  type    = string
  default = "76.76.21.21"
}

variable "vercel_cname" {
  type    = string
  default = "cname.vercel-dns.com"
}

variable "pages_target" {
  description = "Cible Cloudflare Pages : <projet>.pages.dev"
  type        = string
}

variable "railway_api_target" {
  description = "CNAME Railway (prod) affiché lors de l'ajout du custom domain"
  type        = string
}

variable "railway_staging_target" {
  description = "CNAME Railway (staging)"
  type        = string
}

variable "spf_record" {
  type    = string
  default = "v=spf1 -all"
}

variable "dmarc_record" {
  type    = string
  default = "v=DMARC1; p=reject; rua=mailto:dmarc@gwouangmeu.com"
}
