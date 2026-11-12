---
name: feedback-git-branch-tracking
description: Create feature branches with --no-track and push with an explicit refspec; a plain push -u from a branch tracking origin/main landed a commit on main
metadata:
  node_type: memory
  type: feedback
  originSessionId: 300f7397-a909-4daa-a4c8-ccaf3cf73d8c
  modified: 2026-11-12T02:32:03.596Z
---

Create branches with `git switch --no-track -c <name> origin/main` and push with `git push origin refs/heads/<name>:refs/heads/<name>`. Never hide push output with `| tail`.

**Why:** `git switch -c feat/x origin/main` set upstream to `origin/main`, and `git push -u origin feat/x` pushed the commit straight to `main` (fw-web `ea8b7ed`, rollkit org entry, no PR review). The owner chose to keep it, but it skipped review on an infra change.

**How to apply:** every new branch in fw-web and the other catesworks repos; check `git ls-remote --heads origin <name>` after pushing.
