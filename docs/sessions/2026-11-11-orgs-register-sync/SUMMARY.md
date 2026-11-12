# Summary

## What was done

### fw-web

- **`rollkit` product org.** `ea8b7ed` added `rollkit` to `local.zitadel_product_orgs` in `infra/zitadel-product-orgs.tf`. It reached `main` without a PR (see LESSONS). The owner kept it, an independent reviewer approved it after the fact (code read only), and the owner applied it on 2026-11-11 with a saved targeted plan: 3 added, 0 changed, 0 destroyed. Org `399221076892057958`, machine user `rollkit-terraform` `399221083250622822` with `ORG_OWNER` on its own org only. The ids are recorded in the 1Password item `fw-web/zitadel-product-orgs/prod`. The org-scoped JWT-profile key was minted into `fw-web/zitadel-rollkit-terraform/prod` (13-month expiry, 2027-12-11) without being printed.
- **PR #14 merged (`1b10994`).** Sets `allow_register = false` on `zitadel_default_login_policy.fleetworks`. Not applied. See ADR 0001.
- **PRs #9 and #15 closed** as superseded. zitadel-emails-worker will carry the uptimeloom and hullstock From addresses in a later batch PR once their SES identities verify.
- **PR #20 open** (docs): a per-org add procedure in `docs/plans/zitadel-product-orgs.md`.
- **From-pattern PRs from other sessions**, not mine: #11 (linkweave), #16 (formweave and collectweave), #18 (LineOS), #19 (bookweave). All merged. zitadel-emails-worker reported the IAM applies done with the owner's approval and a live policy of six From addresses.

### hostinger

- **PR #57 merged (`246f1b5`).** Adds the env-sync manifest path, a 12-step cross-repo onboarding order and the touchpoints outside hostinger to the `onboard-service-to-hostinger` skill. The section is marked as relayed from linkweave-worker. Nothing in it was verified first-hand.

### Coordination

- Collected status from the linkweave, zitadel-emails, hostinger and env-sync sessions at the start. env-sync was not actually part of the rollout.
- Asked every product session whether it relies on the instance-default hosted Register, and who owns each open PR. Results are in ADR 0001.
- Answered peer questions about fw-web structure, brand, Zitadel conventions and the state backend. Where the answer was unknown, the reply said so.

## Verification state

- The `rollkit` plan showed exactly 3 to add, 0 to change, 0 to destroy before the apply, and the apply matched.
- The stored 1Password items were read back for field names and lengths only. No secret value was printed.
- #14 is **not** applied and has not been planned. Whether API user creation works with `allow_register = false` is supported by a search of the Zitadel source, not tested live.
