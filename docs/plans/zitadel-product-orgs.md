# Plan: create product Zitadel orgs centrally in fw-web

Status: owner approved scope 2026-11-04 (8 orgs + org-scoped machine user + ORG_OWNER membership, no key resource). Implemented in `infra/zitadel-product-orgs.tf`; nothing applied. Date: 2026-11-04.

## Goal

Create one Zitadel org per product on `id.fleetworks.dev` from `infra/zitadel.tf`, in one reviewed change that the owner applies once. Products then take the org id as `zitadel_org_id` and create project/apps/users inside it. The zitadel-emails receiver maps sender and brand by the org of the user a notification is about.

## Scope (needs owner decision)

The brief named 5 products. Two more sessions confirmed they need an org: `hullstock`, `collectweave`. Peers' answers (all information, none an approval):

| Product | Org name | Drafted/applied org creation? | Users in org | Non-default at creation |
| --- | --- | --- | --- | --- |
| bookweave | `bookweave` | No (PR #6 SES/DNS, #7 project only) | Owner only (single user); decision pending whether the owner user moves into this org | No |
| formweave | `formweave` | No (local dev scripts only) | All end users + `formweave-registrar` machine user | No |
| linkweave | `linkweave` | No | None planned (owner user lives in fleet org, project+user grant) | No |
| pipeo | `pipeo` AND `pipeo-staff` (two orgs; plan D12) | No (no zitadel Terraform in repo; bead pipeo-dmb open) | `pipeo`: customer humans; `pipeo-staff`: operators. Staff mail gets neutral sender unless that org is also mapped | No at creation; `force_mfa` for pipeo-staff later (org policy, pipeo repo) |
| uptimeloom | `uptimeloom` | No (draft infra/zitadel has no org resource) | All end users self-register into the org (org-scoped login); owner via project grant | Org login policy must allow registration (product repo) |
| hullstock | `hullstock` | No (local script only, refuses non-loopback) | Humans granted by hand, owner first | Org login policy `allow_register=false` (product repo, org-level override) |
| collectweave | `collectweave` | No | Self-registered designers; owner in fleet org (project grant) | Org login policy must allow registration (product repo) |

No collisions found: no peer has created or drafted an org on the prod instance. zitadel-emails confirms `orgs: {}` in `config/senders.json`; org name is irrelevant to the receiver (only the id), names must be unique per instance.

## Resource shape

In `infra/zitadel.tf` (new section "Product orgs"), one per product:

```hcl
resource "zitadel_org" "bookweave" {
  name       = "bookweave"
  is_default = false

  lifecycle {
    prevent_destroy = true # destroying an org deletes all its users and data
  }
}

output "bookweave_org_id" {
  description = "Zitadel org id for bookweave (not a secret). Hand to the bookweave repo as zitadel_org_id."
  value       = zitadel_org.bookweave.id
}
```

(Repeat for each product. Attribute names verified against provider 3.3 schema during Phase B.) Nothing else: no policies, no members, no projects.

## Naming

Lowercase product slug, exactly as above. Matches the peers' requests and the `auth.<product>.catesworks.dev` From convention. Names are unique per instance and renaming later is possible in Zitadel, but the id is what everything keys on.

## Open design points surfaced by peers (owner decisions)

1. **Users in the org decide the sender.** The receiver maps by the org of the user the notification is about. bookweave, linkweave and collectweave plan to keep the owner's existing user in the Fleetworks org and use a project grant. Mail about that user will use the neutral Fleetworks sender, not the product sender. If product-branded mail is wanted for the owner's logins, the owner needs a user inside each product org. Peers are asking the owner; this does not change the org resources, only what users land in them.
2. **Org-scoped machine users for in-org Terraform.** bookweave, formweave, collectweave, hullstock asked this plan to also create an org-scoped machine user (e.g. `<product>-terraform`, ORG_OWNER on its org only) and hand over its key. linkweave asks what permissions to expect and notes project/user grants in the owner's (fleet) org may need broader scope. Recommendation: create **no** machine users or keys in this change. Reasons: a `zitadel_machine_key` or PAT puts a secret in the shared `fleetworks/hub` state; scope stays at "exactly the approved orgs, 0 other"; the owner can mint each key in the Console in one minute and store it in 1Password. Alternative if wanted: add `zitadel_machine_user` + `zitadel_org_member` (ORG_OWNER) per org with no key resource (no secret in state), and the owner mints keys by hand. Cross-org grants (linkweave, bookweave, collectweave) need rights in the fleet org, which an ORG_OWNER on the product org does not have; those grants would have to be applied by the owner with a broader credential or restructured (users in the product org).
3. **Org-level login policy** (hullstock: registration off; collectweave: registration on) belongs to each product's Terraform with its org-scoped credential, not to this change.

## Targeted plan (must be exactly N add / 0 change / 0 destroy: 6 for the original five products (pipeo has two orgs), 8 with hullstock and collectweave)

Never plan or apply the full root: no real `terraform.tfvars` here; defaults would propose destroying the SES identity and `id.fleetworks.dev` DNS; the root also has unrelated unapplied commits (`zitadel_application_oidc.warden_mobile` create, lhci machine users destroy).

```bash
cd infra
export AWS_PROFILE=workloom AWS_REGION=us-east-2
export TF_VAR_cloudflare_account_id=placeholder TF_VAR_cloudflare_api_token=placeholder \
  TF_VAR_zitadel_org_id=placeholder \
  TF_VAR_yellow_pages_supabase_ref=placeholder TF_VAR_helmsman_supabase_ref=placeholder \
  TF_VAR_rolodex_supabase_ref=placeholder TF_VAR_warden_supabase_ref=placeholder \
  TF_VAR_chorus_supabase_ref=placeholder
terraform plan -lock-timeout=60s \
  -target=zitadel_org.bookweave -target=zitadel_org.formweave -target=zitadel_org.linkweave \
  -target=zitadel_org.pipeo -target=zitadel_org.pipeo_staff -target=zitadel_org.uptimeloom
```
(add `-target=zitadel_org.hullstock -target=zitadel_org.collectweave` if approved)

Method follows zitadel-emails `LESSONS.md` and fw-web PR #4. The plan reads state (S3 `fleetworks/hub`) and the zitadel provider uses `infra/zitadel-provider-key.json` implicitly; I read neither the key nor state. Only counts and resource addresses go in the PR.

## Review

Independent reviewer session/agent on the head commit (not me); fix findings; re-request on new head; draft PR to ready only with the owner's OK. fw-web has no branch protection, so review is the gate.

## Apply (owner only, never me)

With the owner's own credential (the terraform IAM_OWNER provider key and S3 state access), same env as above:

```bash
terraform apply -lock-timeout=60s \
  -target=zitadel_org.bookweave ... (same -target list as the plan)
```

Review the plan output: N to add (6 or 8), 0 to change, 0 to destroy, then confirm. Apply from a merged `main` checkout so state and code agree. Do not run `terraform apply` without `-target`.

## Returning the ids

After the apply, I read the ids with `terraform output -raw <product>_org_id` (non-sensitive outputs only; no `terraform show`, no state dump) and send them by message to each product session and zitadel-emails-worker, with the next-step reminder.

## Rollback

- Before any user/project exists in the org: delete the mistaken empty org. `prevent_destroy` blocks this by design. Deliberate steps: a small PR removing the `lifecycle` block on that one resource, a targeted `terraform plan -target=zitadel_org.<x>` showing exactly 1 destroy, owner applies. Or delete in the Console and `terraform state rm` the resource.
- Once users/projects exist: do not destroy; deletion is irreversible data loss.
- A wrong name: rename in place (1 change) rather than destroy/recreate.

## Risks

- Shared-instance mutation: 6-8 new orgs on `id.fleetworks.dev`; additive only, no existing org touched. Org names must not collide; peers report none, and the plan refresh will fail on a duplicate at apply time (Zitadel errors on duplicate name).
- Pending unrelated drift in the root is untouched by `-target`; Terraform will warn that the plan is partial.
- State locking: other applies to `fleetworks/hub` (e.g. IAM changes) hold the S3 lock; use `-lock-timeout`, and apply while no one else applies.
- Org-scoped credentials cannot do cross-org grants (see open point 2).
- A peer's local dev scripts create orgs named `formweave`/`Fleetworks` on localhost:8089 only; not a prod risk.
- I cannot list live orgs read-only without the owner's tooling; known orgs (from the zitadel-emails session): Fleetworks 384119342113037522, LineOS 396152745595240786, LineOS-Staff 396152745712681298. Owner: please confirm no product org already exists.

## Order after apply

1. Orgs applied (owner) -> I send ids.
2. Each product applies its SES identity (own infra root, per `onboard-a-product.md` step 2).
3. Each product opens its two mapping PRs: zitadel-emails (`brands.ts`, `config/senders.json`, test) and fw-web (`local.zitadel_emails_from_patterns` in `infra/zitadel-emails-iam.tf`).
4. zitadel-emails does one bundled release; fw-web IAM policy applied via a separate targeted plan (1 change).

## Owner decisions (2026-11-04)

- Scope: all 8 orgs (bookweave, collectweave, formweave, hullstock, linkweave, pipeo, pipeo-staff, uptimeloom).
- Per org also a `<org>-terraform` machine user + `ORG_OWNER` membership. NO key/PAT resource: the owner mints each JWT-profile key in the Console and stores it in 1Password `infra-access`, item `fw-web/zitadel-<org>-terraform/prod` (naming per secrets-source-of-truth). Peers are told that location, never the key.
- Resulting targeted plan: **24 to add, 0 to change, 0 to destroy** (8 orgs + 8 machine users + 8 memberships). The resource shape is `for_each` over a set, with map outputs `product_org_ids` and `product_terraform_user_ids`.
- Targets: `zitadel_org.product`, `zitadel_machine_user.product_terraform`, `zitadel_org_member.product_terraform`.
