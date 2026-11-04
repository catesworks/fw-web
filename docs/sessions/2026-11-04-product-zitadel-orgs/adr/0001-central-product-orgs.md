# 0001: Create product Zitadel orgs centrally in fw-web

Status: accepted (owner, 2026-11-04)

## Context

The zitadel-emails receiver chooses a notification's sender and brand from the org of the user it is about. Each product therefore needs its own org on the shared instance. Creating an org needs the instance IAM_OWNER credential, which only the owner applies with.

## Decision

- Orgs are created in this repo (`infra/zitadel-product-orgs.tf`), eight of them, with `prevent_destroy`. Product repos receive `zitadel_org_id` and manage their own project, apps and users inside the org.
- Each org gets an `<org>-terraform` machine user with `ORG_OWNER` on that org only. No key resource in Terraform, so no private key enters the shared state.
- The fw-web session mints the keys on the owner's explicit go, using the hub IAM_OWNER provider key read only by the script, with a 13-month expiry, straight into 1Password `infra-access`. The owner accepted this use of the credential.

## Consequences

- One reviewed change, one owner apply, one place that knows every org.
- `ORG_OWNER` is broad inside its org (can add owners, mint keys, change policies, possibly delete the org); keys must stay in 1Password and be rotated before expiry.
- One `prevent_destroy` block covers all orgs; removing one mistaken empty org needs a deliberate PR and a plan showing exactly three destroys.
- Cross-org grants are out of reach of these keys.
