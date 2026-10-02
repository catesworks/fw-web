# fw-web: push readiness for unpushed local commits (2026-10-01)

- **Range:** `origin/main..e76805a`: **3 commits**, all authored 2026-10-01 (10:27 to 16:57 local) by Andrew Cates (agent co-authored).
- **Size:** 7 files, +131 / -17.
- **State:** nothing is pushed. No migrations, env vars or workflow changes.
- **Verified:** at `15d271e`. The only later commit is a bead-state sync.

## 1. What changed

- `1384f68` (fw-agp) adds `src/app/error.tsx`, `src/app/global-error.tsx` (its own html/body), **new** `src/app/not-found.tsx`, and `src/app/status.module.css`.
  - They use `role="alert"` and a `reset()` retry button.
  - User-visible effect: branded error and 404 pages replace the Next.js defaults.
- `15d271e` fixes a **syntax error already on origin/main** in `scripts/render-brand-logo.mjs`. It also marks the `playwright` import in `scripts/zitadel-bootstrap.mjs` with `eslint-disable import/no-unresolved`, because playwright is not a dependency. Lint and format go green.
- `e76805a` is a `.beads/interactions.jsonl` sync only.

## 2. Migrations

None.

## 3. Env vars / secrets / GitHub settings

None.

## 4. Deploy steps / owner actions

The only in-repo workflow is `release-please.yml`, which runs on push to `main` and opens or updates a release PR. There is no deploy workflow in `.github/workflows/`, and the repo does not say how the site is hosted. Confirm whether a Vercel Git integration (or similar) deploys `main` on push.

No needs-user beads are specific to this repo.

## 5. Risks

- Low. The new pages only render on error or 404. `global-error.tsx` replaces the root layout when it renders, so it does not use the site layout's fonts or styles.

## 6. Verification evidence

Bead **fw-nhau**:

- First pass at `1384f68`: typecheck and build PASS. Lint and format FAILED on the pushed `render-brand-logo.mjs` syntax error. That was fixed by `15d271e`.
- **RE-VERIFICATION 2 at `15d271e`: GREEN.** The repo has no tests.
- `e76805a` touches only `.beads/`, so no re-run is needed.

## 7. Known open defects

None tracked for this repo.

## 8. Suggested PR split

1. `1384f68 15d271e`: error boundaries + lint fix
2. `e76805a`: bead sync (or fold it into PR 1)

**Cross-repo push order:**

1. fw-monorepo (docs/ADRs)
2. cogs (pushing opens the "Version Packages" PR, and merging it publishes)
3. **fw-web**
4. fw-yellow-pages
5. fw-chorus and fw-warden
6. fw-rolodex

fw-web has no code dependency on the others.

## 9. Rollback

Revert the merge commit. Nothing else holds state.
