# Session dossier: product Zitadel orgs (2026-11-04)

Session `fw-web-worker`. Created eight Zitadel orgs for the fleet's products on `id.fleetworks.dev` through fw-web Terraform, minted their org-scoped machine keys, and handed the ids to the product sessions.

## State in one paragraph

Done and applied: eight orgs, eight `<org>-terraform` machine users with `ORG_OWNER` on their own org, eight keys in 1Password, two calendar reminders. Mid-flight and not mine: five draft fw-web PRs (#8 to #12) that add each product's From address to the worker's IAM policy; zitadel-emails-worker owns that batch and will open one combined PR. Nothing is blocked on this session.

## Repo state

| Repo | Branch | HEAD | Notes |
| --- | --- | --- | --- |
| `catesworks/fw-web` | `main` | `3811fcb` (PR #7) | #6 (`811bc14`) added `infra/zitadel-product-orgs.tf` and the plan doc; #7 documented the key-minting credential. Applied by the owner (24 added, 0 changed, 0 destroyed). |

Open PRs in fw-web belong to product sessions: #8 formweave, #9 uptimeloom, #10 collectweave, #11 linkweave, #12 bookweave. All edit the same list in `infra/zitadel-emails-iam.tf`, so they conflict after the first merge.

## Resume prompt

> Resume the product Zitadel orgs work in /usr/local/repos/catesworks/fw-web. Read `docs/sessions/2026-11-04-product-zitadel-orgs/README.md` and `FOLLOWUPS.md`. State: eight orgs, machine users and keys are applied and stored; the sender-mapping batch (fw-web #8 to #12) belongs to zitadel-emails-worker. Next: nothing owed by this session; ask zitadel-emails-worker where the batch stands.

## Read first

1. `docs/plans/zitadel-product-orgs.md` (decisions, apply, rollback, risks)
2. `infra/zitadel-product-orgs.tf`
3. `FOLLOWUPS.md` and `adr/0001-central-product-orgs.md` in this dossier

## First action

Ask zitadel-emails-worker for the status of the combined From-pattern PR before touching #8 to #12.
