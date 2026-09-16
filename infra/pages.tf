# No `source` block: the project accepts direct uploads only. GitHub Actions
# builds the site and pushes it with `wrangler pages deploy`. Adding a
# `source` block would make Cloudflare build on every push as well, and each
# push to main would deploy twice.
resource "cloudflare_pages_project" "site" {
  account_id        = var.cloudflare_account_id
  name              = var.project_name
  production_branch = "main"

  deployment_configs = {
    production = {
      compatibility_date = "2026-04-01"
    }
    preview = {
      compatibility_date = "2026-04-01"
    }
  }
}

# Attaches the custom hostname to the project. Cloudflare issues the
# certificate once the CNAME in dns.tf resolves.
resource "cloudflare_pages_domain" "site" {
  account_id   = var.cloudflare_account_id
  project_name = cloudflare_pages_project.site.name
  name         = var.site_name
}
