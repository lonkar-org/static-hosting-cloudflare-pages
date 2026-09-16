# Proxied CNAME from the hostname to the project's *.pages.dev subdomain.
# Cloudflare flattens the CNAME at the zone apex, so "@" works.
resource "cloudflare_dns_record" "site" {
  zone_id = var.cloudflare_zone_id
  name    = var.dns_record_name
  content = cloudflare_pages_project.site.subdomain
  type    = "CNAME"
  proxied = true
  ttl     = 1 # 1 means "automatic" on proxied records
}
