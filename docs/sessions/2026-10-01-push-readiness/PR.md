# fw-web: error boundaries + lint fix (do not merge until owner pre-checks)

## Summary

- `1384f68` (fw-agp): adds `src/app/error.tsx`, `src/app/global-error.tsx` (own html/body), new `src/app/not-found.tsx`, and `src/app/status.module.css`. Branded error and 404 pages (`role="alert"`, `reset()` retry button) replace the Next.js defaults.
- `15d271e`: repairs a syntax error already on `main` in `scripts/render-brand-logo.mjs`, and marks the `playwright` import in `scripts/zitadel-bootstrap.mjs` with `eslint-disable import/no-unresolved` (playwright is not a dependency). Lint and format go green.
- `e76805a`: `.beads/interactions.jsonl` bead-state sync only.
- `c683c4d`, `60adb4f`: docs-only push-readiness dossier.

## Migrations

None.

## Env / secrets

None. No env vars, secrets, GitHub settings or workflow changes.

## Deploy / owner steps

- The only in-repo workflow is `release-please.yml` (runs on push to `main`, opens or updates a release PR). There is no deploy workflow here.
- Owner: confirm whether a Vercel Git integration (or similar) deploys `main` on merge.

## Risks

Low. The new pages render only on error or 404. `global-error.tsx` replaces the root layout when it renders, so it does not use the site layout's fonts or styles.

## Verification

Clean detached worktree at verified HEAD `c683c4d` (Node v24.1.0, pnpm 10.33.0). Commits after it (`60adb4f`) are docs-only.

- `pnpm install --frozen-lockfile`: PASS
- `pnpm typecheck`: PASS
- `pnpm lint`: PASS
- `pnpm format:check`: PASS
- `pnpm build`: PASS (Next.js 15.5.21, 13/13 static pages)
- `pnpm test`: N/A (no test script)

Non-blocking warnings: Next ESLint plugin not detected; host `${NPM_TOKEN}` `.npmrc` warning.

## Known open issues

None tracked for this repo.

## Rollback

Revert the merge commit. Nothing else holds state.

## Pre-merge checklist

- [ ] Owner has reviewed this PR and the owner pre-checks are done
- [ ] CI green on this PR
- [ ] Confirmed how `main` is deployed (Vercel Git integration or other)
- [ ] Reviewed the new error/404 pages visually if desired
- [ ] Do NOT merge until the above is complete

🤖 Generated with [Claude Code](https://claude.com/claude-code)
