# Plan: create product Zitadel orgs centrally in fw-web

Status: owner approved scope on 2026-11-04. Implemented in `infra/zitadel-product-orgs.tf` (PR #6). Nothing applied yet.

## Goal

Create one Zitadel org per product on `id.fleetworks.dev` from this Terraform root, in one reviewed change that the owner applies once. Each product repo then takes its org id as `zitadel_org_id` and manages its project, apps and users inside that org. The zitadel-emails receiver maps sender and brand by the org of the user a notification is about.

## Decisions (owner, 2026-11-04)

- Scope: 8 orgs: bookweave, collectweave, formweave, hullstock, linkweave, pipeo, pipeo-staff, uptimeloom. Names are the lowercase product slug.
- Per org: a machine user `<org>-terraform` with an `ORG_OWNER` membership on that org only (never IAM_OWNER).
- No key or PAT resource. After the apply, and only on the owner's explicit go, fw-web-worker mints each JWT-profile key through the Zitadel API with a 13-month expiry and writes it straight into 1Password vault `infra-access`, item `fw-web/zitadel-<org>-terraform/prod` (via a 0600 template, never printed; the owner approves the 1Password prompts). Peers get that location, never the key. The owner's Google Calendar gets a rotation reminder per key, 30 days before expiry. Minting touches only the new `<org>-terraform` user in its own org.
- Minting credential (owner accepted, 2026-11-04): the hub IAM_OWNER provider key `infra/zitadel-provider-key.json`, read only by the minting script to obtain a short-lived token, never printed. Call: `POST /management/v1/users/{id}/keys` with `type: KEY_TYPE_JSON`, an `expirationDate` 13 months out, and header `x-zitadel-orgid: <product org id>`. `{id}` is `product_terraform_user_ids[<org>]` and the org id is `product_org_ids[<org>]` (PR #6 outputs). The short-lived token needs the scope `urn:zitadel:iam:org:project:id:zitadel:aud`. The response holds the private key as base64 in `keyDetails`: the script base64-decodes it so the 1Password item holds the usable key JSON, never logs it, and writes it straight into 1Password. The 0600 template file is created under `umask 077` and removed by `trap 'rm -f "$tmp"' EXIT` (so cleanup also runs if the write fails or a prompt is declined), and its absence is checked. (v1 Management API is deprecated in favor of v2 `POST /v2/users/{userId}/keys`; v1 still works.)
- pipeo-staff is mapped to the same email sender as pipeo (owner decision relayed by zitadel-emails-worker), so no extra SES identity or From pattern is needed.

## What peers reported

No peer has drafted or applied an org creation on the prod instance, so there are no collisions. bookweave and linkweave put the owner's sign-in user inside their own org, so the per-org machine user is enough for them. collectweave still plans a project grant into the fleet org, which an `ORG_OWNER`-on-own-org user cannot create (it needs a broader credential or the same redesign). hullstock wants registration off and collectweave and uptimeloom want registration on in the org login policy; those policies belong to each product's own Terraform. Known pre-existing orgs: Fleetworks 384119342113037522, LineOS 396152745595240786, LineOS-Staff 396152745712681298. The owner confirmed no product org exists.

## Resource shape

`for_each` over `local.zitadel_product_orgs` (a set of names):

- `zitadel_org.product[<name>]`: `is_default = false`, `lifecycle { prevent_destroy = true }` (destroying an org deletes all its users and data).
- `zitadel_machine_user.product_terraform[<name>]`, `zitadel_org_member.product_terraform[<name>]` (`ORG_OWNER`).
- Outputs (ids only, not secrets): `product_org_ids`, `product_terraform_user_ids`, both maps keyed by org name.

## Targeted plan

Never plan or apply the full root. It has no real `terraform.tfvars` on this machine, so the defaults would propose destroying the SES identity and the `id.fleetworks.dev` DNS records. It also has unrelated unapplied commits (`zitadel_application_oidc.warden_mobile` create, lhci machine users destroy).

```bash
cd infra
export AWS_PROFILE=workloom AWS_REGION=us-east-2
export TF_VAR_cloudflare_account_id=placeholder TF_VAR_cloudflare_api_token=placeholder \
  TF_VAR_zitadel_org_id=placeholder TF_VAR_yellow_pages_supabase_ref=placeholder \
  TF_VAR_helmsman_supabase_ref=placeholder TF_VAR_rolodex_supabase_ref=placeholder \
  TF_VAR_warden_supabase_ref=placeholder TF_VAR_chorus_supabase_ref=placeholder
terraform plan -lock-timeout=60s \
  -target=zitadel_org.product \
  -target=zitadel_machine_user.product_terraform \
  -target=zitadel_org_member.product_terraform
```

The result must be exactly **24 to add, 0 to change, 0 to destroy** (8 orgs, 8 machine users, 8 memberships). Anything else: stop. The placeholders are unused by the targeted resources. The zitadel provider reads `infra/zitadel-provider-key.json` implicitly. Terraform warns that targeting is in effect; that is expected. Method follows zitadel-emails `LESSONS.md` and fw-web PR #4.

## Review

An independent reviewer reviews the head commit (not the author). Fixes go on the same branch, then re-review on the new head. fw-web has no branch protection, so the review is the gate. Merge only with the owner's OK.

## Apply (owner only)

From a checkout of merged `main`, with the owner's own credential and the same environment as the plan:

```bash
terraform apply -lock-timeout=60s \
  -target=zitadel_org.product \
  -target=zitadel_machine_user.product_terraform \
  -target=zitadel_org_member.product_terraform
```

Confirm the plan summary says 24 to add, 0 to change, 0 to destroy before typing `yes`. Never apply without `-target`.

## Returning the ids

```bash
terraform output -json product_org_ids
terraform output -json product_terraform_user_ids
```

If the outputs come back empty after a targeted apply (unconfirmed whether Terraform writes them), read the ids from the Console instead. Only these non-sensitive outputs are read; no `terraform show` and no state dump. The ids are sent by message to each product session and to zitadel-emails-worker (all eight, name to id). After applying, fw-web-worker mints each machine key on the owner's go (see Decisions).

## Rollback

`prevent_destroy` is on the one `zitadel_org.product` resource block, so it covers all eight orgs at once. Lifting it lifts it for every org. To remove one mistaken, EMPTY org:

1. In a small PR, delete that org's name from `local.zitadel_product_orgs` and temporarily remove the `prevent_destroy` line.
2. A targeted plan, `-target='zitadel_org.product["<name>"]' -target='zitadel_machine_user.product_terraform["<name>"]' -target='zitadel_org_member.product_terraform["<name>"]'`, must show exactly 3 to destroy (member, machine user, org), all for that name, and nothing else.
3. The owner applies it. A follow-up PR restores `prevent_destroy`.

Alternative: delete the org in the Console, then run `terraform state rm` for that name's three resources and remove the name from the set in the same PR; otherwise the next apply recreates the org. Do not do either once the org has users or projects: deletion is irreversible data loss.

Renaming is not an in-place change. The name is the `for_each` key and part of the machine user's `user_name`, so editing it plans a destroy and recreate, which `prevent_destroy` blocks. To rename, rename in the Console and keep the key unchanged (add `ignore_changes = [name]` if Terraform then shows drift), or move to a map of key to name first.

## Risks

- Shared-instance mutation: 8 new orgs, additive only; no existing org or resource is touched. A duplicate name would fail at apply time.
- `ORG_OWNER` is broad inside its org: it can add other owners, mint keys or PATs for any user in the org, and change org policies and IdPs, none of which `prevent_destroy` covers. It may also be able to delete its own org (unverified; verify before handing out keys). Treat each key as high-value: 1Password `infra-access` only, 13-month expiry, rotate before it.
- `prevent_destroy` protects only against Terraform. A delete in the Console or API bypasses it.
- Zitadel may add the creating user (the hub `terraform` IAM_OWNER user) as a member of each new org. That adds no real access but shows in member lists.
- The unrelated pending drift in this root is untouched by `-target`.
- State locking: other applies to `fleetworks/hub` hold the S3 lock; use `-lock-timeout` and avoid concurrent applies.
- Cross-org grants (collectweave) cannot be made by the per-org machine user.

## Order after the apply

1. The owner applies; I send the ids to all sessions.
2. On the owner's go, fw-web-worker mints the eight machine keys into 1Password and creates the calendar reminders.
3. Each product applies its SES identity (own infra root).
4. Each product opens its two mapping PRs: zitadel-emails (`brands.ts`, `config/senders.json`, test) and fw-web (`local.zitadel_emails_from_patterns` in `infra/zitadel-emails-iam.tf`). pipeo adds two `senders.json` entries (pipeo and pipeo-staff, same brand and From) and one From pattern.
5. zitadel-emails does one bundled release; fw-web's IAM policy change is a separate targeted plan.
