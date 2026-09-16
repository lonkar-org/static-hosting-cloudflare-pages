output "site_url" {
  value = "https://${var.site_name}"
}

output "pages_subdomain" {
  value = cloudflare_pages_project.site.subdomain
}
