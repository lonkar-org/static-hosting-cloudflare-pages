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

## Step 2: Create a Cloudflare account

1. Sign up at [dash.cloudflare.com/sign-up](https://dash.cloudflare.com/sign-up)
   with the email from step 1. Verify the email.
2. Turn on two-factor authentication:
   [Cloudflare 2FA guide](https://developers.cloudflare.com/fundamentals/user-profiles/2fa/).
3. Note your **account id**. It is on the right side of any zone overview
   page once you have a domain, and in the URL of the dashboard after login:
   `dash.cloudflare.com/<account id>`.
   [Find account and zone IDs](https://developers.cloudflare.com/fundamentals/account/find-account-and-zone-ids/).

The free plan covers everything in this repo. Do not upgrade.

## Step 3: Put a domain on Cloudflare

Cloudflare needs to be the DNS provider for your domain, so it can point the
domain at your site and issue the HTTPS certificate. Two ways to get there.

**Buy a new domain.** Cloudflare Registrar sells domains at cost, with DNS
already set up.
[Register a domain](https://developers.cloudflare.com/registrar/get-started/register-domain/).

**Move an existing domain.** Keep the domain where it is and change its
nameservers to Cloudflare's. Cloudflare imports your existing DNS records
during setup.
[Full setup guide](https://developers.cloudflare.com/dns/zone-setups/full-setup/setup/).
Nameserver changes take minutes to a day to spread.

Either way you end up with a **zone** in the dashboard, one per domain. Open
it and note the **zone id** from the right column of the overview page. You
now have both ids this repo needs:

| Name       | Looks like                         | Used for                        |
| ---------- | ---------------------------------- | ------------------------------- |
| account id | 32 hex characters                  | Pages project, R2 bucket, token |
| zone id    | 32 hex characters, different value | DNS record                      |

Neither id is a password, but this repo treats them as secrets so they stay
out of the code.

## Step 4: Turn on R2 and create the state bucket

Terraform writes down what it created in a file called **state**. GitHub
Actions runs on a fresh machine every time, so the state has to live
somewhere shared. This repo stores it in **R2**, Cloudflare's file storage.
[What Terraform state is](https://developer.hashicorp.com/terraform/language/state).
[R2 overview](https://developers.cloudflare.com/r2/).

1. In the dashboard open **R2 Object Storage** and enable it. Cloudflare asks
   for a payment card here. The free tier includes 10 GB of storage and a
   million writes a month; a Terraform state file is a few kilobytes.
   [R2 pricing](https://developers.cloudflare.com/r2/pricing/).
2. Log in to Wrangler, Cloudflare's command line tool, from your terminal.
   It opens a browser window.

   ```sh
   npx wrangler login
   ```

3. Create the bucket. This repo uses `tfstate-demos`; pick your
   own name, bucket names are unique per account.

   ```sh
   npx wrangler r2 bucket create tfstate-demos
   ```

Write the bucket name down. Step 7 puts it in `infra/backend.config`.

Terraform cannot create this bucket for you, because the bucket has to exist
before Terraform can store anything. This is the one piece of infrastructure
you create by hand.
[Wrangler commands](https://developers.cloudflare.com/workers/wrangler/commands/).

## Step 5: Create two API tokens

Tokens let Terraform and Wrangler act on your Cloudflare account without your
password. Scope each one to the least it needs.

**R2 token**, for reading and writing the state file.

1. Dashboard, **R2 Object Storage**, **Manage API tokens**, **Create API token**.
2. Permission: **Object Read and Write**. Specify bucket: the one from step 4.
3. Copy the **Access Key ID** and **Secret Access Key**. The secret is shown
   once.

[R2 API tokens](https://developers.cloudflare.com/r2/api/tokens/).

**Cloudflare API token**, for creating the Pages project and the DNS record.

1. Dashboard, profile menu, **My Profile**, **API Tokens**, **Create Token**,
   **Create Custom Token**.
2. Permissions, two rows:
   - Account, **Cloudflare Pages**, Edit
   - Zone, **DNS**, Edit
3. Zone Resources: Include, Specific zone, your domain.
4. Create, then copy the token. Also shown once.

[Create an API token](https://developers.cloudflare.com/fundamentals/api/get-started/create-token/).

Check both tokens before going further. Every mistake below shows up later
as a bare "Authentication error" or "AccessDenied", so two curl calls now save
a confusing failure in step 9. Replace the placeholders with your values:

```sh
# Cloudflare token: both calls must print "success":true
curl -s -H "Authorization: Bearer <cloudflare api token>" \
  "https://api.cloudflare.com/client/v4/accounts/<account id>/pages/projects" | head -c 120; echo
curl -s -H "Authorization: Bearer <cloudflare api token>" \
  "https://api.cloudflare.com/client/v4/zones/<zone id>/dns_records?per_page=1" | head -c 120; echo
```

For the R2 token, the quickest check is step 10: `terraform init` against the
bucket. The mistakes I made while writing this: pasted the R2 token where the
Cloudflare token goes, scoped the R2 token to a bucket that no longer
existed, and forgot the account-level Pages permission on the Cloudflare
token. Each one was a bare authentication error with no hint which token.

You now hold five values. Keep them in a password manager until step 9.

| Value                 | From   |
| --------------------- | ------ |
| account id            | step 2 |
| zone id               | step 3 |
| R2 access key id      | step 5 |
| R2 secret access key  | step 5 |
| Cloudflare API token  | step 5 |

## Step 6: Add the site

`site/` holds what Cloudflare Pages serves. This repo ships two plain HTML
files so the pipeline has something to deploy. Replace them with your own.

- Plain HTML, CSS and JS: put the files in `site/`.
- A generator such as Vite, Astro or Hugo: keep the source wherever you like
  and make the build write to `site/`, or point the deploy step in step 8 at
  your build's output folder.

`404.html` at the root of the folder is served for unknown paths.
[Pages serving behaviour](https://developers.cloudflare.com/pages/configuration/serving-pages/).

## Step 7: Describe the hosting in Terraform

Terraform turns infrastructure into text. You write what you want, run
`terraform apply`, and Terraform calls the Cloudflare API to make it so. Run
it again after an edit and it changes only what differs.
[What is Terraform](https://developer.hashicorp.com/terraform/intro).

Terraform reads every `.tf` file in `infra/` as one configuration.

| File               | What it does                                                     |
| ------------------ | ---------------------------------------------------------------- |
| `providers.tf`     | Loads the Cloudflare plugin. Declares that state lives in an S3-compatible store. |
| `pages.tf`         | The Pages project, and your domain attached to it.               |
| `dns.tf`           | A CNAME record pointing your domain at the project.              |
| `variables.tf`     | Inputs: hostname, project name, record name, ids and token.      |
| `outputs.tf`       | Values printed after apply, such as the site URL.                |
| `terraform.tfvars` | Your non-secret inputs. Edit this one.                           |
| `backend.config`   | Where the state file lives. Edit the bucket name.                |

Edit two files:

1. `infra/terraform.tfvars`

   ```hcl
   site_name       = "blog.example.com"   # hostname the site is served on
   dns_record_name = "blog"               # "@" for example.com itself
   project_name    = "static-hosting-cloudflare-pages"   # becomes <project_name>.pages.dev
   ```

2. `infra/backend.config`: set `bucket` to the name from step 4.

The rest of `backend.config` is copied from
[Cloudflare's R2 backend guide](https://developers.cloudflare.com/terraform/advanced-topics/remote-backend/).
The `skip_*` flags stop Terraform from calling AWS-only services that R2 does
not have. `use_lockfile` makes Terraform write a lock object next to the state
so two runs cannot apply at the same time.

Resource reference for the Cloudflare plugin:
[cloudflare_pages_project](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/pages_project),
[cloudflare_pages_domain](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/pages_domain),
[cloudflare_dns_record](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/dns_record).

## Step 8: Add the GitHub Actions workflow

GitHub Actions runs commands on GitHub's machines when you push. The steps
are listed in `.github/workflows/deploy.yml`.
[Understand GitHub Actions](https://docs.github.com/en/actions/get-started/understand-github-actions).

What the workflow does, in order:

| Step                 | On which branches | What it does                                        |
| -------------------- | ----------------- | --------------------------------------------------- |
| `terraform fmt`      | all               | Fails if a `.tf` file is not formatted.             |
| `terraform init`     | all               | Downloads the Cloudflare plugin, connects to R2.    |
| `terraform validate` | all               | Checks the files for errors.                        |
| `terraform plan`     | all               | Prints what would change. Nothing changes yet.      |
| `terraform apply`    | `main` only       | Applies that plan.                                  |
| `wrangler pages deploy` | `main` only    | Uploads `site/` to the Pages project.               |

Pushing a branch and opening a pull request gives you the plan in the job
log. Merge, and `main` applies the same plan. The upload uses Wrangler through
the official [wrangler-action](https://github.com/cloudflare/wrangler-action).

Edit one thing: `--project-name=static-hosting-cloudflare-pages` on the last step must match
`project_name` in `infra/terraform.tfvars`.

The tokens appear only as `${{ secrets.NAME }}`. Step 9 stores them in GitHub.
[Using secrets in GitHub Actions](https://docs.github.com/en/actions/security-for-github-actions/security-guides/using-secrets-in-github-actions).

## Step 9: Create the GitHub repo, add secrets, push

1. Create your repository. This repo is a
   [template repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-template-repository),
   so **Use this template** on GitHub gives you a copy without this history.
   [Create a repository from a template](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template).
   Or clone and push to a new empty repo.
2. Repository, **Settings**, **Secrets and variables**, **Actions**,
   **New repository secret**. Add the five values from step 5:

   | Secret name             | Value                 |
   | ----------------------- | --------------------- |
   | `CLOUDFLARE_ACCOUNT_ID` | account id            |
   | `CLOUDFLARE_ZONE_ID`    | zone id               |
   | `CLOUDFLARE_API_TOKEN`  | Cloudflare API token  |
   | `R2_ACCESS_KEY_ID`      | R2 access key id      |
   | `R2_SECRET_ACCESS_KEY`  | R2 secret access key  |

3. Commit your edits from steps 6 to 8 and push to `main`.
4. Open the **Actions** tab and watch the run. The plan step lists three
   resources to add. Apply creates them. Deploy uploads the site.
5. Open `https://<your hostname>`. Cloudflare issues the certificate after
   the DNS record exists, which takes a minute or two on first deploy. Until
   then the browser may show a certificate warning. Wait, then reload.

From now on, every push to `main` redeploys. Every push to another branch
shows a plan and touches nothing.

## Step 10: Deploy from your machine

Optional. The workflow does all of this on push. Run it by hand to see a plan
before pushing, to deploy before the GitHub repo exists, or to run
`terraform destroy` in step 11.

1. Install Terraform (step 1).
2. Copy `.env.example` to `.env` and fill in the five values from step 5. The
   file uses the same names as the GitHub secrets and derives the rest, so
   Terraform, the R2 backend and Wrangler all read from it. `.env` is ignored
   by git.
3. Load it and run Terraform:

   ```sh
   set -a; source .env; set +a
   cd infra
   terraform init -input=false -backend-config=backend.config
   terraform plan
   terraform apply
   cd ..
   ```

   `init` connects to the same state in R2 that GitHub Actions uses, so your
   laptop and the workflow see the same picture. A plan that shows
   "No changes" means the live setup matches the files.
   [Terraform CLI tutorial](https://developer.hashicorp.com/terraform/tutorials/cli/init).

4. Upload the site. Wrangler reads `CLOUDFLARE_API_TOKEN` and
   `CLOUDFLARE_ACCOUNT_ID` from the environment, so no `wrangler login` is
   needed in this shell:

   ```sh
   npx wrangler pages deploy ./site --project-name=static-hosting-cloudflare-pages --branch=main
   ```

   Same command the last workflow step runs. Wrangler prints the deployment
   URL when it finishes.

## Step 11: Tear it all down

In reverse order of creation.

1. Remove the Pages project, domain and DNS record. From step 10's shell:

   ```sh
   cd infra
   terraform destroy
   ```

2. Delete the state bucket. It must be empty first; `destroy` leaves a small
   state file behind.

   ```sh
   npx wrangler r2 object delete tfstate-demos/static-hosting-cloudflare-pages/infra.tfstate
   npx wrangler r2 bucket delete tfstate-demos
   ```

3. Revoke both tokens. R2, **Manage API tokens**; and **My Profile**,
   **API Tokens**.
4. Delete the five GitHub secrets, or the repository.

The domain stays. Cloudflare Registrar domains renew yearly until you turn
auto-renew off in the Registrar page.
