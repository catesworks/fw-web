---
name: project-orgs-register-sync-2026-11
description: "State of fw-web product orgs, rollkit org and allow_register=false (merged, not applied) as of 2026-11-11, with the dossier path to resume from"
metadata:
  node_type: memory
  type: project
  originSessionId: 300f7397-a909-4daa-a4c8-ccaf3cf73d8c
  modified: 2026-11-12T02:32:02.592Z
---

fw-web-worker session, 2026-11-07 to 2026-11-11. Rollkit Zitadel org applied (org 399221076892057958) and its key minted into 1Password `infra-access` item `fw-web/zitadel-rollkit-terraform/prod` (expires 2027-12-11). fw-web PR #14 (`allow_register = false` on the instance default login policy) is MERGED but NOT APPLIED: live default is still true. #9 and #15 closed; zitadel-emails-worker owns the next From-pattern batch.

**Why:** a multi-session rollout (linkweave, zitadel-emails, hostinger and product sessions) depends on this order: product org, own SES identity verified, fw-web IAM From pattern applied BEFORE the zitadel-emails release.

**How to apply:** resume from `docs/sessions/2026-11-11-orgs-register-sync/README.md` and `FOLLOWUPS.md` in fw-web. Owner applies hub Terraform from their terminal with `AWS_PROFILE=workloom` and per-instance `-target`. Never push a new branch with `git push -u` from a branch tracking `origin/main` (see [[feedback-git-branch-tracking]]).
