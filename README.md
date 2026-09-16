# Static hosting on Cloudflare Pages with Terraform and GitHub Actions

[![Plan and deploy](https://github.com/lonkar-org/static-hosting-cloudflare-pages/actions/workflows/deploy.yml/badge.svg)](https://github.com/lonkar-org/static-hosting-cloudflare-pages/actions/workflows/deploy.yml)
[![Live site](https://img.shields.io/website?url=https%3A%2F%2Fexample.lonkar.org&label=example.lonkar.org)](https://example.lonkar.org)
[![Cloudflare Pages](https://img.shields.io/badge/Cloudflare-Pages-F38020?logo=cloudflare&logoColor=white)](https://developers.cloudflare.com/pages/)
[![Terraform](https://img.shields.io/badge/Terraform-~%3E%201.10-844FBA?logo=terraform&logoColor=white)](https://developer.hashicorp.com/terraform)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Use this template](https://img.shields.io/badge/Use%20this-template-2ea44f?logo=github)](https://github.com/lonkar-org/static-hosting-cloudflare-pages/generate)

Companion repo for the post
[Free static hosting with Cloudflare Pages, Terraform and GitHub Actions](https://yogesh.lonkar.org/posts/static-hosting-cloudflare-pages-terraform.html).

Everything runs on Cloudflare's free tier. No AWS account.

## How to read this repo

The git history is the tutorial. Each commit is one step, and each step adds
its own section to this README. Run `git log --reverse --oneline` to see the
steps in order, or read this file top to bottom.

## Step 1: What you need before you start

Accounts and things that cost money:

- An email address you control. Cloudflare and GitHub both send verification
  mail to it.
- A [GitHub account](https://github.com/signup). Free plan is enough.
- A payment card. Cloudflare asks for one before it turns on R2, and you pay
  for the domain with it. Nothing else in this setup is billed.
- A domain, or about 10 USD a year to buy one in step 3.

Tools on your machine:

- [Git](https://git-scm.com/downloads).
- [Node.js](https://nodejs.org/en/download) 22 or newer. It runs `npx wrangler`,
  Cloudflare's command line tool, in step 4.
- [Terraform](https://developer.hashicorp.com/terraform/install) 1.10 or
  newer. Optional. GitHub Actions runs Terraform for you; install it only if
  you want to run plans from your laptop (step 10).

Knowledge:

- Basic git: clone, commit, push.
- Basic terminal use.
- No prior Terraform, DNS or GitHub Actions experience. Each step explains what
  it uses and links to the official docs.

Security habits worth adopting from the start:

- Turn on two-factor authentication on
  [GitHub](https://docs.github.com/en/authentication/securing-your-account-with-two-factor-authentication-2fa)
  and [Cloudflare](https://developers.cloudflare.com/fundamentals/user-profiles/2fa/).
- Never commit a token or secret. `.gitignore` in this repo excludes `.env`,
  Terraform state and plan files.
