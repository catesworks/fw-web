# Product orgs on the shared Zitadel instance (id.fleetworks.dev).
#
# Orgs are instance-level objects, so they are created centrally here (this root
# holds the instance IAM_OWNER provider key); each product repo then takes its org
# id as `zitadel_org_id` and manages its own project/apps/users inside that org.
# The zitadel-emails receiver picks a notification's sender and brand from the org
# of the user the notification is about (see catesworks/zitadel-emails,
# docs/runbooks/onboard-a-product.md).
#
# Per org this creates ONLY: the org, one `<org>-terraform` machine user and its
# ORG_OWNER membership (scoped to that org alone, never IAM_OWNER). It does NOT
# create a machine key or PAT: a key's private half would land in this shared
# state. fw-web-worker mints the JWT-profile key via the API on the owner's go and
# stores it straight in 1Password (vault `infra-access`, item `fw-web/zitadel-<org>-terraform/prod`).
#
# NEVER `terraform apply` this root unscoped (it cannot be planned honestly without
# its real terraform.tfvars). Plan and apply with -target, see
# docs/plans/zitadel-product-orgs.md.
locals {
  # Org name = key. Lowercase product slug.
  zitadel_product_orgs = toset([
    "bookweave",
    "collectweave",
    "formweave",
    "hullstock",
    "linkweave",
    "pipeo",
    "pipeo-staff",
    "uptimeloom",
  ])
}

resource "zitadel_org" "product" {
  for_each = local.zitadel_product_orgs

  name       = each.key
  is_default = false

  lifecycle {
    # Destroying an org deletes all of its users and data. Lift this deliberately
    # (it covers ALL orgs) only to remove one mistaken EMPTY org. It does not stop a
    # delete in the Console or API.
    prevent_destroy = true
  }
}

resource "zitadel_machine_user" "product_terraform" {
  for_each = local.zitadel_product_orgs

  org_id            = zitadel_org.product[each.key].id
  user_name         = "${each.key}-terraform"
  name              = "${each.key} Terraform (org-scoped)"
  description       = "Applies the ${each.key} repo's infra/zitadel (project, apps, roles, grants) inside the ${each.key} org only"
  access_token_type = "ACCESS_TOKEN_TYPE_JWT"
}

# ORG_OWNER is needed so the product repo can write org policies (login policy),
# projects, apps, users and grants in its org. Blast radius: a holder of this key can
# add owners, mint keys/PATs for any user in the org and change its policies/IdPs,
# and possibly delete the org (unverified). Owner of the key: Andrew Cates, stored in
# 1Password infra-access. Keys are minted with a 13-month expiry (rotate before
# expiry; reminders are on the owner's calendar).
resource "zitadel_org_member" "product_terraform" {
  for_each = local.zitadel_product_orgs

  org_id  = zitadel_org.product[each.key].id
  user_id = zitadel_machine_user.product_terraform[each.key].id
  roles   = ["ORG_OWNER"]
}

output "product_org_ids" {
  description = "Zitadel org id per product org (not a secret). Hand each to its repo as zitadel_org_id."
  value       = { for k, o in zitadel_org.product : k => o.id }
}

output "product_terraform_user_ids" {
  description = "Machine user id per product org (not a secret). Mint its JWT-profile key in the Console."
  value       = { for k, u in zitadel_machine_user.product_terraform : k => u.id }
}
