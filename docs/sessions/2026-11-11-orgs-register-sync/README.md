# Session dossier: product orgs and hosted-registration sync (2026-11-07 to 2026-11-11)

Session `fw-web-worker`. Coordinated the fw-web side of a multi-session product rollout on the shared Zitadel hub (`id.fleetworks.dev`): answered peer sessions, merged and closed the open fw-web PRs, turned off hosted self-registration in the instance default (merged, not applied), created the `rollkit` product org and minted its key, and updated the hostinger onboarding skill.

## State in one paragraph

Done: the `rollkit` org, its machine user and its membership are applied (3 added) and its ids and key are in 1Password. PR #14 (`allow_register = false` on the instance default) is merged but **not applied**, so the live default is still `true`. PRs #9 and #15 are closed as superseded by zitadel-emails-worker's next batch. The IAM From-pattern PRs #11, #16, #18 and #19 are merged and applied by zitadel-emails-worker. PRs #20 (docs, per-org add procedure) and #21 (this dossier) are merged. Batch 3 From-pattern PRs #22 (uptimeloom), #23 (hullstock) and #24 (pipeo) were merged by zitadel-emails-worker after this dossier was first written; whether their IAM applies and SES identity checks are done was NOT verified here. Calendar reminders for the rollkit key exist (2027-11-11 rotate, 2027-12-11 expiry). Blocked on the owner: the scoped apply of #14, and an approval decision on the public blog post (not written).

## Repo state

| Repo                 | Branch / state                                    | Last commit                                          | Notes                                                                                                         |
| -------------------- | ------------------------------------------------- | ---------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| `catesworks/fw-web`  | `main`                                            | `96bab41` on 2026-11-12                              | Includes #14 (`1b10994`), #20 (`31402a9`), #21 (`2bf2ba3`) and batch 3 PRs #22, #23, #24. `ea8b7ed` (rollkit org entry) was pushed to `main` without a PR by mistake; the owner chose to keep it. |
| `catesworks/hostinger` | `main`                                          | `246f1b5` (#57, squash-merged by this session)       | Skill `onboard-service-to-hostinger`: cross-repo onboarding order. Relayed from linkweave-worker, unverified. |

Nothing is applied from #14 or from the docs PRs. `infra/rollkit.tfplan` was deleted by the owner after the apply.

## Resume prompt

> Resume the product orgs and hosted-registration work in /usr/local/repos/catesworks/fw-web. Read `docs/sessions/2026-11-11-orgs-register-sync/README.md` and `FOLLOWUPS.md`. State: rollkit org applied and keyed; #14 merged but not applied; #9 and #15 closed; #20, #21 and batch 3 PRs #22-#24 merged. Next: ask the owner whether uptimeloom's `infra/zitadel` is applied, then help them run the scoped plan for #14 (`-target=zitadel_default_login_policy.fleetworks`, expect 1 change).

## Read first

1. `FOLLOWUPS.md`
2. `adr/0001-turn-off-hosted-registration-by-default.md`
3. `LESSONS.md`
4. `docs/plans/zitadel-product-orgs.md` (see "Adding one more org later")
5. `infra/zitadel.tf`, resource `zitadel_default_login_policy.fleetworks`

## First action

Ask the owner (or uptimeloom-worker) whether uptimeloom's `infra/zitadel` has been applied. Then, if the owner wants #14 live, have them run `terraform plan -lock-timeout=60s -target=zitadel_default_login_policy.fleetworks` with the same environment as the product-orgs plan, and check that it shows exactly 1 change.
