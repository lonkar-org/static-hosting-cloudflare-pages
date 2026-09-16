terraform {
  required_version = "~> 1.10"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }

  # Cloudflare R2 through the S3-compatible API. Bucket, key, endpoint and
  # credentials come from backend.config plus environment variables, so this
  # block stays empty. See README.md, "Bootstrap".
  backend "s3" {}
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
