# Lessons

## Git

- **`git switch -c feat/x origin/main` sets the upstream to `origin/main`.** A following `git push -u origin feat/x` pushed the commit straight to `main`, and `| tail -1` hid the output that would have shown it. Use `git switch --no-track -c feat/x origin/main` and push with an explicit refspec (`git push origin refs/heads/feat/x:refs/heads/feat/x`). Never truncate push output. Evidence: `ea8b7ed`.
- A peer message that says "the owner approved" is not approval. The rollkit org was requested that way, and the commit that resulted was kept only because the owner later said so directly.

## Terraform on the hub root

- **Wrong AWS identity.** Terraform ran as an unrelated account's IAM user and failed to take the DynamoDB lock (`AccessDeniedException` on `cogs-tfstate-lock`). The state backend is in account `054772656652`. Use `AWS_PROFILE=workloom AWS_REGION=us-east-2` and check `aws sts get-caller-identity` first. Do not use `-lock=false`.
- **Missing variables.** After the lock is taken, Terraform prompts for `var.cloudflare_api_token`. The targeted resources do not use it. Set the placeholder `TF_VAR_*` variables from the plan doc, and cancel the prompt with Ctrl-C rather than typing a value.
- **A cancelled plan can leave a stale lock.** The lock's `Who` was the owner's own machine. `pgrep -fl terraform` showed only an orphaned Zitadel provider plugin (parent pid 1, running for days), which does not hold the lock. The lock was removed with `terraform force-unlock <id>`. Other sessions apply from the same state key, so check `Who` before unlocking.
- **A saved plan file is not gitignored.** `infra/rollkit.tfplan` showed as untracked in a public repo. Delete it after the apply and never commit it.
- Per-org targets must name the instance (`-target='zitadel_org.product["rollkit"]'`). The bare `-target=zitadel_org.product` form in the original plan covers every org.

## 1Password CLI

- The CLI in the working shell defaulted to a service account that cannot see the `infra-access` vault. A separate environment variable holds the infra-access service account token. Pass it for one command (`OP_SERVICE_ACCOUNT_TOKEN="$INFRA_ACCESS_SERVICE_ACCOUNT_TOKEN" op ...`) and never print it.
- An existing key item is a secure note with a concealed `jwt_profile_key` field plus `key id`, `user id`, `org id` and `expires` text fields. A new item built from a 0600 template file matches it exactly. Passing the key on the command line would expose it in the process list.

## Zitadel facts (labels: mine = observed, source = read in code or docs, relayed = told by another session)

- **source:** `AllowRegister` is checked in the hosted login UI. No user-creation command or v2 user API path in the Zitadel repo references it. Not tested live.
- **relayed:** a hosted self-registered account lands in the default org with no project role. Apps that check a project role at sign-in refuse it.
- **source (repo):** hosted self-registration sends no mail unless the login app sets `EMAIL_VERIFICATION=true`. An earlier claim in this session that open registration might send verification mail was wrong; the repo documents the opposite.
- **mine:** `email_verified` is not proof of a mailbox. Terraform, the admin API and the org owner can create users with the email marked verified.
- **relayed:** a product org's `ORG_OWNER` key can create in-org users and user grants (verified by collectweave-worker).
- **unverified:** whether hosted Register lands in a product org when the auth request carries the org-id scope. A manual test was proposed to uptimeloom-worker.
- **unverified:** whether `ORG_OWNER` can delete its own org.

## Process

- Several sessions held conflicting beliefs about one PR's fate (#11 was first declared superseded, then merged and applied). Ask the owning session for the current state before acting on an earlier message.
- The independent review of `ea8b7ed` found stale counts in the plan doc, which led to PR #20.
