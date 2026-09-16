variable "site_name" {
  description = "Hostname the site is served on, for example example.com or blog.example.com"
  type        = string
}

variable "project_name" {
  description = "Cloudflare Pages project name. Also the *.pages.dev subdomain."
  type        = string
}

variable "cloudflare_account_id" {
  description = "Cloudflare account id"
  type        = string
  sensitive   = true
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token with Pages:Edit and DNS:Edit"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Zone id of the domain that site_name belongs to"
  type        = string
  sensitive   = true
}

variable "dns_record_name" {
  description = "Record name under the zone: \"@\" for the apex, \"blog\" for blog.example.com"
  type        = string
  default     = "@"
}
