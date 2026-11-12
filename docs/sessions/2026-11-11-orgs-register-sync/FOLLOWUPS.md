# Follow-ups

## Blocked on the owner

1. Apply #14 with a scoped plan: `terraform plan -lock-timeout=60s -target=zitadel_default_login_policy.fleetworks`, expect exactly 1 change, then apply the same target. Do it after uptimeloom's `infra/zitadel` is applied. Use `AWS_PROFILE=workloom` and the placeholder `TF_VAR_*` variables.
2. Check batch 3 (#22 uptimeloom, #23 hullstock, #24 pipeo): each From pattern is only usable once its IAM policy is applied, its SES identity returns true/SUCCESS/SUCCESS, and SES_ALLOWED_FROM_PATTERNS is updated. Ask zitadel-emails-worker for the state before applying anything.
3. Done 2026-11-12: calendar reminders for the rollkit key (rotation 2027-11-11, expiry 2027-12-11). The earlier eight keys expire 2027-12-04 (reminders already exist).
4. Decide whether `ea8b7ed` needs more than the after-the-fact review it already had (the owner chose to keep it).
5. Decide whether the public blog post for this work should be written. None was written, because the repo is public and the owner has not approved publishing.
6. Apply uptimeloom's `infra/zitadel` (org login policy with registration on) and `infra/ses` from the owner's terminal. These are product-repo applies, not fw-web.
7. Create collectweave's designers by hand (console or Terraform). The owner chose this over an org policy with registration on.

## Blocked on remaining work

1. zitadel-emails-worker's next batch: a fresh fw-web PR with only verified From addresses (uptimeloom, hullstock, pipeo, rollkit as their SES identities verify). Gate: `get-email-identity` shows `VerifiedForSendingStatus` true, DKIM `SUCCESS` and MAIL FROM `SUCCESS`. The IAM apply must come before the zitadel-emails release.
2. Test, on a throwaway user, that creating a user through the Zitadel API still works with `allow_register = false`. formweave's registrar flow and its refusal tests are the first real exercise of this.
3. Test whether hosted Register lands in a product org when the auth request carries the org-id scope (uptimeloom is the candidate).
4. Verify the hostinger skill's 12-step onboarding order against the next product that onboards. It is marked relayed and unverified.
5. Verify whether `ORG_OWNER` can delete its own org in this Zitadel version (open since 2026-11-04).
6. hullstock-worker asked to be told when #14 is applied, so it can refresh a comment that tracks the instance default. It was told on merge, not on apply.
7. Owner decisions 2026-11-12, relayed to env-sync-worker (it must confirm them with the owner): the shared agent-run infra doc lives in the env-sync `secrets-crud` skill, and an agent may type `y` into a tmux TTY confirm only after the owner approves that exact step in the agent's own session, for the named target only. Never `ENV_SYNC_ALLOW_LOCAL_YES`. About a dozen product sessions had asked fw-web-worker for this; it did not own those answers.
