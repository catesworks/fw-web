# Lessons

## Verified facts

- A targeted plan on the three `for_each` resources (`zitadel_org.product`, `zitadel_machine_user.product_terraform`, `zitadel_org_member.product_terraform`) showed 24 to add, 0 to change, 0 to destroy, and the apply matched. Placeholder `TF_VAR_*` values were enough because the targeted resources use none of them.
- The real `terraform.tfvars` does not exist on this machine or in the repo checkout (`infra/*.tfvars` is gitignored). A plain `terraform plan` of the whole root would propose destroying the SES identity and the `id.fleetworks.dev` DNS records. Do not run it. Terraform's "Applied changes may be incomplete, run terraform plan" warning is a generic `-target` message, not a task here.
- Key minting: a short-lived token from the hub provider key (scope `urn:zitadel:iam:org:project:id:zitadel:aud`), then `POST /management/v1/users/{id}/keys` with `KEY_TYPE_JSON`, `expirationDate` and `x-zitadel-orgid`. `keyDetails` is base64; the stored item holds the decoded key JSON.
- `op` works only outside the sandbox, with desktop approval, after unsetting `OP_SERVICE_ACCOUNT_TOKEN` and `OP_LATEST_SERVICE_ACCOUNT_TOKEN`, with `</dev/null`.
- `for_each` makes one `prevent_destroy` block cover all eight orgs. Removing one org later means lifting protection for all of them for the duration, guarded by a plan showing exactly three destroys for that name.

## Mistakes and process

- I repeated Terraform's "run terraform plan" suggestion to the owner without saying it was not needed here. It confused them. Say plainly when a tool's generic advice does not apply.
- The first rollback and command text in the plan doc was written for single resources and was wrong after switching to `for_each`. The independent review caught it. Re-read docs after changing the code shape.
- Reviewer-flagged and still unverified: whether `ORG_OWNER` can delete its own org. Treat the keys as able to.
