# Plan: Register production Zitadel OIDC clients for rolodex (web + mobile) + Lighthouse — REVISION 5

Status: **EXECUTED (2026-08-25).** Critic APPROVED (iteration 5), Architect ARCHITECTURALLY SOUND (iteration 4). Steps 1-7 complete against production `id.fleetworks.dev`; Step 8 stop-checkpoint held. Phase 2 (real-account migration, env wiring, coordinated deploy) not started.

## Phase 1 execution record (2026-08-25)

- **Step 0a/1-2**: `zitadel.tf` gained `rolodex_web` (`app_type = OIDC_APP_TYPE_WEB`) and `rolodex_mobile` (`app_type = OIDC_APP_TYPE_NATIVE`), both public/PKCE/JWT, matching the approved shape exactly.
- **Step 3-4**: baseline captured (clean, zero diff — no perpetual SMTP-password drift as it turned out); targeted plan showed exactly 2 additions, 0 changes, 0 destroys; full untargeted plan showed the same 2 additions with zero collateral diff on any other resource, including `zitadel_project.fleetworks_suite` and `zitadel_email_provider_smtp.ses`.
- **Step 4a**: the existing `rolodex` (Supabase) client's `client_id`/`client_secret` backed up to `infra/rolodex-supabase-client-backup.json` (gitignored) before apply.
- **Step 5**: applied. `rolodex_web` real client_id `387884804516945106`; `rolodex_mobile` real client_id `387884804567211218`.
- **Step 6**: pre-mortem #2 resolved concretely, better than the plan's fallback — the `zitadel/zitadel ~> 3.3` provider exposes `zitadel_machine_user`/`zitadel_personal_access_token`/`zitadel_instance_member`, so Lighthouse's two identities went through Terraform (Principle 2, no exception needed) rather than the script/console fallback: `lhci_seed_bot` (plain machine user, Session API caller) and `lhci_login_client` (a **dedicated** `IAM_LOGIN_CLIENT`-scoped machine user via `zitadel_instance_member`, distinct from the shared login-client identity that powers every app's hosted login UI). Both PATs generated, stored in `infra/lighthouse-zitadel-pats.json` (gitignored) alongside the two client_ids Phase 2 needs for `AUTH_AUDIENCE`/`ZITADEL_CLIENT_ID`. A `lhci-zitadel-test@fleetworks.dev` human user was also created for Lighthouse's own login. One real drift caught and fixed mid-execution: the PAT resources' `expiration_date` wasn't pinned, and Terraform wanted to replace both (rotating them) to reconcile toward null — fixed by pinning the attribute to the actual server-assigned value (`9999-12-31T23:59:59Z`) before it could destroy the just-captured tokens.
- **Step 7**: standalone verification, both real, browser-driven logins against production (not scripted Session-API calls) — `rolodex_web`: full authorize→real login→code→token round trip returned all three of a 3-segment JWT `access_token`, `id_token`, `refresh_token`; refresh grant succeeded with a rotated `refresh_token` and a fresh JWT `access_token`. `rolodex_mobile`: SSO carried the session straight through with no re-login, delivering a real code to `rolodex://auth/callback`, exchanged successfully. Fly logs for `fleetworks-zitadel` during the verification window: zero `level=error` entries, only `0`/`200`/`302` response statuses.
- **`phase1-verify`**: created, used for Step 7, then deleted per the plan's default disposition (its only purpose was Step 7, which succeeded) — config and state reconciled with a final zero-diff plan.
- **Step 8**: held. No Render/Vercel/EAS env vars touched, no deploys triggered, no `users` table mutation, `apps/web/vercel.json`'s `deploymentEnabled.main` still `false`.

## Revision 5 changelog (round 4 Critic → APPROVED)

Critic's round-4 REVISE (light — no CRITICAL, 4 MAJOR) required 4 changes,
all applied and independently re-verified (including a fresh live probe of
the Render finding, matching Critic's result exactly) before requesting the
final check that returned APPROVED:

- **`zitadel_project.fleetworks_suite` added to the abort-list** (AC#1 and
  pre-mortem #1), with the reasoning stated: `-target` pulls in a targeted
  resource's dependencies, and both new apps reference this project's
  `id`, so it's necessarily included in the targeted apply — its settings
  govern all 5 existing apps' tokens/branding, not just the 2 new ones.
- **`phase1-verify` given a lifecycle**: password-storage convention
  (matching `zitadel-admin-password.txt`), coverage in pre-mortem #3
  alongside Lighthouse's account, and a forced decision in its AC —
  delete after Step 7, or explicitly record retaining it for Phase 2.
- **The Render `autoDeploy` claim corrected from config-derived to
  observed.** A live probe (independently re-run, matching Critic's
  result) shows `POST /internal/testing/zitadel-session` (added by
  `dcf5d10`, on `origin/main`) returns `404`, while the older
  `/internal/testing/magic-link` returns `401` (exists, gated) —
  `testingRoutes` mounts unconditionally, so the deployed API predates
  `dcf5d10` and hasn't picked up several subsequent commits either,
  despite `render.yaml`'s `autoDeploy: true` and no `buildFilter`. _Why_
  is unconfirmed and stated as such, not assumed safe. Corrected in Ground
  Truth, the risks table, Step 8, and cross-referenced into both
  `rolodex/docs/RENDER-RUNBOOK.md` and `FOLLOWUPS.md` (`6a30db5`, pushed).
- **Public-vs-confidential decided, not deferred.** Asked directly; the
  user chose public (PKCE, no secret) — simpler, no `apps/web` change
  needed, matches current code. Recorded as final for Phase 1 in Open
  Questions and Principle 4, with the rationale for deciding now (a later
  switch would invalidate Phase 1's own AC#4/#5 verification) preserved.

Also folded in while the file was open: abort-list resource-count
reconciled (five vs. six, in both AC#1 and pre-mortem #1); Principle 4's
stale "deferred" wording updated to reflect the decision; the risks
table's standing-credential row extended to cover `phase1-verify`
alongside Lighthouse; the `safeDecodeIdToken` citation in AC#5 corrected
to the actual refresh-path mechanism (`tokens.claims()` + fallback, not
`safeDecodeIdToken`, which is only used against the stored cookie's
`id_token` in the non-refresh branch).

## Post-round-4 polish

Architect round 4 returned **ARCHITECTURALLY SOUND — zero principle
violations**, with one required one-line fix and three optional ones,
applied directly rather than spun into another full revision cycle (per
Architect's own recommendation not to hold this for a fifth round):

- **Required:** AC#5's refresh-leg assertion was over-scoped — it required
  `id_token` on the refresh grant, which `apps/web/src/app/api/session/route.ts:104-108`
  doesn't require and OIDC Core §12.2 makes optional. Fixed: `id_token` is
  now required only on the initial exchange (matching `callback/route.ts:94-95`);
  the refresh leg requires only `access_token` (matching `session/route.ts:104-108`).
- The Option B recommendation's reasoning was corrected — it had credited
  phase _isolation_ with catching this session's config errors, when
  _review_ caught them (Option C gets the same review). Replaced with the
  argument that actually holds: a client nothing depends on is cheap to
  destroy and recreate if a later-discovered error requires it.
- Open Questions' confidential-vs-public entry: removed the last trace of
  citing `oidc-client.ts`'s current behavior as a reason (the same
  circularity Principle 4 already disowns), and added that a later switch
  would invalidate Phase 1's own AC#4/#5 verification, not just require a
  new `client_id`.
- Pre-mortem #1 now names all 5 resources in its own text, not just via a
  forward reference to AC#1.

## Revision 4 changelog (round 3 → round 4)

Round 3 was reviewed by Architect (NEEDS REVISION — 1 blocker, 3 majors, 3
minors). All addressed:

- **Finding Q (blocker) — fixed.** AC#1 had accidentally dropped
  `zitadel_email_provider_smtp.ses` from the abort-list entirely while
  pre-mortem #1 still claimed it was monitored. Restored with an
  **attribute-scoped** carve-out (write-only `password` diff expected and
  benign; any other attribute of that resource aborts, same as the other
  four) — reconciled in both AC#1 and pre-mortem #1. Also corrected the
  SMTP bug's documented trigger ("updating a live SMTP config," not
  "re-sending the password").
- **Finding R (major) — fixed.** The confidential-vs-public decision for
  `rolodex_web` is now actually recorded (Open Questions), with the
  circular `oidc-client.ts`-cites-the-plan-that-caused-it justification
  removed from Principle 4.
- **Finding S (major) — fixed.** AC#5 now asserts the token response
  contains `id_token` (not just `access_token`/refresh), matching
  `callback/route.ts:94-95`'s hard requirement — closing the same
  wrong-but-legal-and-undetected gap pre-mortem #4 was written about, this
  time applied to this revision's own new decision.
- **Finding P (major) — fixed.** `FOLLOWUPS.md`'s stale "nothing pushed
  yet" section corrected; cross-referenced from `docs/RENDER-RUNBOOK.md`
  (`7d9324d`, pushed) — the more likely place a stranger looks.
- **Finding N (minor, carried from round 2) — fixed.** The `rolodex`
  client's id/secret backup now has an owning step (4a) and an AC, not
  just a risks-table mention.
- **Finding O (minor, carried from round 2) — fixed.** Option C's cons
  rewritten to the real tradeoff (one coordinated window vs. two, against
  Principle 1) instead of an invented "unscheduled deploy" premise.
- **Finding T (minor) — fixed.** Pre-mortem header corrected to "(4
  scenarios)"; the Freeze Exit Trigger section moved after the Ground
  Truth bullet list instead of splitting it.

## Revision 3 changelog (round 2 → round 3)

Round 2 was reviewed by Architect (NEEDS REVISION — 2 new blockers, both
independently verified as fixed elsewhere) and Critic (REVISE — 1 critical,
2 major). Both independently converged on the same critical finding, which
is the headline fix here:

- **`app_type` corrected from `OIDC_APP_TYPE_USER_AGENT` to
  `OIDC_APP_TYPE_WEB`** (both `rolodex_web`'s AC and Step 1). Verified
  independently (not taken on either report): `apps/web/src/app/auth/login/route.ts`
  and `apps/web/src/app/auth/callback/route.ts:59-88` run the entire PKCE
  exchange server-side in a Next.js route handler
  (`client.authorizationCodeGrant` executes in Node, the verifier lives in
  an HttpOnly cookie, never in browser JS) — a backend-for-frontend, not a
  browser SPA. `USER_AGENT` is Zitadel's SPA classification; `WEB` is the
  server-side one, and it's also what all 5 existing apps already use
  (`zitadel.tf:52,93`). Principle 4 is corrected to derive this from the
  architecture, not from the local dev seed's port-derived blanket default
  (whose own comment says "browser Auth Code+PKCE" — a premise that never
  applied to rolodex's real implementation). `auth_method_type = NONE`
  stays correct either way — `oidc-client.ts` already uses `client.None()`.
  Whether to instead go **confidential** (`WEB` + `BASIC`, since a Node
  route handler _can_ hold a secret) is recorded as a deliberate, explicit,
  deferred decision rather than something Phase 1 silently forecloses.
- **Render's `autoDeploy` — investigated, decision made by the user, not
  this plan.** Both reviewers flagged that `render.yaml` is still armed
  while the plan claimed the trapdoor was closed. Asked directly: the user
  will independently verify migration `0012`'s production-DB status and
  `@cogs/auth@0.6.0`'s token-audience-check compatibility with current
  Supabase tokens, and has chosen to leave Render's `autoDeploy` as-is for
  now rather than freeze the API too. Recorded as a **conscious, informed
  choice**, not a dropped finding — see Ground Truth and Risks below.
- **Freeze exit trigger, made explicit.** Architect's other blocker: the
  Vercel disarm (Phase 0) froze _all_ rolodex web production deploys
  indefinitely, with no stated end. Fixed: the trigger is named (Phase 2's
  kickoff — see "Freeze exit trigger" below) and a discoverable note was
  added to `rolodex`'s session dossier `FOLLOWUPS.md` (the established
  handoff-tracking location for this work), not left to live only inside
  this plan file.
- **Terraform plan baseline, not an absolute no-diff rule.** AC#1's
  abort-list previously risked being unsatisfiable by construction — the
  SMTP resource's `password` attribute is write-only and not persisted in
  state, so it may show a perpetual diff regardless of this plan's changes.
  Fixed: capture the full untargeted `terraform plan` diff as a **recorded
  baseline** before touching anything, then compare against that baseline,
  not against an assumed-clean state.
- **Verification test account named.** Step 6/7 previously left it
  ambiguous whether the "dedicated test account" for the standalone round
  trip was the Lighthouse CI user or a separate account. Fixed: it's a
  **separate**, dedicated `phase1-verify` test account — reusing
  Lighthouse's account for ad-hoc protocol verification would blur that
  account's single purpose and its own drain-token-gated blast-radius
  design.
- **Stale-callback wrinkle noted.** `https://rolodex.fleetworks.dev/auth/callback`
  is still live and served by the _pre-cutover_ Supabase federated-login
  handler (confirmed: `307` today). The standalone round trip will still
  deliver a real `code` to that URL, which the old handler will try to
  consume — Step 7 now says explicitly to capture `?code=` from the
  redirect before that happens, so this isn't misread as a failed test.
- **`id_token_userinfo_assertion` given an explicit position** (it silently
  dropped out of round 2's ACs): deliberately omitted for both new clients,
  since rolodex's own code reads claims directly off the JWT
  (`oidc-client.ts`), unlike the Supabase-relying-party apps which need
  Zitadel to assert userinfo into the ID token for Supabase's linking logic
  (`zitadel.tf:61,99`).
- **New pre-mortem scenario #4**, per both reviewers' point that a
  wrong-but-legal `app_type`/`auth_method_type` combination passes a
  protocol round trip silently — exactly what almost happened here.

## Revision 2 changelog (round 1 → round 2)

Round 1 was reviewed by Architect (NEEDS REVISION, 3 blockers) and Critic
(REJECT, 2 criticals). One critical was independently resolved by a live
production probe during this revision (see "Ground truth" below); the rest
required real plan changes, applied here:

- **Phase 0 executed, not proposed.** Production's Vercel auto-deploy on
  `main` was disarmed (`rolodex/apps/web/vercel.json`
  `deploymentEnabled.main: false`), committed and pushed
  (`cb7a3fc`) — closing the "any unrelated future push silently ships a
  login-breaking build" trapdoor Architect's Finding B identified, _before_
  any further plan work.
- Corrected all 4 wrong/imprecise citations (Critic + Architect both flagged
  these): `seed.ts:283-296` (was `:297-299`), `seed.ts:62-93` (was `:63-101`),
  `zitadel-sso-phase1-cutover.md:337-339` (was `:333-335`),
  `testing.ts:221-226` (was `:220-226`).
- Added a third Option (register clients + restore login now, deferring
  only real-account migration) per Critic's fairness finding — Option A was
  previously strawmanned at its maximal, least-safe form.
- Pinned the full Terraform resource shape in acceptance criteria:
  `app_type`, `response_types`, `grant_types` (including
  `OIDC_GRANT_TYPE_REFRESH_TOKEN`), `dev_mode = false` — all previously
  absent, all load-bearing (Architect D/E/F, Critic §4).
- Resolved the AC#5-vs-AC#7 self-contradiction (Architect G, Critic §5,
  CRITICAL #2): Phase 1's verification is now a **standalone PKCE round
  trip run directly against `id.fleetworks.dev`**, not through any deployed
  app code. Everything requiring a deployed web/API (Lighthouse's actual
  `/internal/testing/zitadel-session` → `/auth/testing-session` flow,
  `AUTH_ISSUER`/`AUTH_AUDIENCE` repoint) moved to Phase 2, since setting
  those on the API is itself a global auth-verification cutover, not a
  scoped test-only change (Critic §5 — this is correct and round 1 missed
  it).
- Scoped the Terraform apply: `-target` for the 2 new resources plus an
  explicit named abort-list (`zitadel_email_provider_smtp.ses`,
  `aws_iam_access_key.ses`, `zitadel_default_login_policy`,
  `zitadel_default_label_policy`) — any diff there stops everything
  (Architect A, Critic §3).
- Rewrote the rollback section: web rollback is `git revert` + redeploy
  (Supabase auth code is deleted from `apps/web`), API rollback is still a
  genuine env flip (`render.yaml`'s `AUTH_ISSUER`/`AUTH_AUDIENCE` are
  dashboard `sync: false`) (Architect C).
- Pinned the Terraform binary (`~/.local/bin/terraform-1.15.8`, per
  `versions.tf`'s own comment — Homebrew's `terraform` is frozen at 1.5.7
  and hard-errors on this root's write-only SMTP password attribute) and
  listed credential prerequisites (Critic §5).
- Left the Terraform-vs-exception question for the Lighthouse machine
  users/PATs as an **open question** (below) rather than asserting an
  unverified answer either way.
- Added a mobile round-trip acceptance criterion (previously only web was
  verified) and the EAS-rebuild-required note for mobile env vars
  (build-time, baked via `app.config.ts`'s `extra`, not runtime).

## Requirements Summary

Resume-prompt scope: "separately and deliberately register the web, mobile,
and Lighthouse OIDC clients on production Zitadel (`id.fleetworks.dev`),
then run the actual production cutover runbook." This plan covers
**Phase 1: client registration + standalone verification only.** Phase 2
(real-account migration, env-var wiring, coordinated web+API deploy,
Lighthouse's actual functional verification) is the existing runbook,
started separately, gated behind its own approval.

## Ground truth (live-verified this session, not just document review)

- Production Zitadel is real, live, Terraform-managed:
  `fleetworks-web/infra/zitadel.tf`, provider `zitadel` (domain
  `id.fleetworks.dev`, JWT-profile auth via the gitignored, IAM_OWNER-scoped
  `infra/zitadel-provider-key.json` — `zitadel.tf:13-16`). This shared root
  also owns Cloudflare DNS for `fleetworks.dev` and the fleet's SES/SMTP
  config (`zitadel.tf:115-141` — documents a real Zitadel projection bug
  triggered by **updating the live SMTP config** (the documented case was a
  port change): `SQLSTATE 42601`, "wedges the projection").
- 5 existing OIDC apps (`yellow_pages` at `zitadel.tf:40-65`, plus
  `{helmsman, rolodex, warden, chorus}` via `for_each` at `zitadel.tf:72-101`)
  are all confidential `OIDC_APP_TYPE_WEB` clients pointed at each product's
  Supabase `/auth/v1/callback` — the legacy `custom:fleetworks` pattern.
  **`zitadel_application_oidc.app["rolodex"]` is the runbook's designated
  rollback fixture and must not be touched by this work** — but see the
  rollback correction below; it is necessary, not sufficient, for a full
  rollback.
- **Neither a public/PKCE `rolodex-web` nor any `rolodex-mobile` client
  exists in Terraform yet.** Rolodex's app-code cutovers (`06be517` web,
  `989090c` mobile) never touched production infra.
- **`06be517` and `989090c` are already merged to `origin/main`.**
  (`git rev-list --count origin/main..main` = 0.) `06be517` deletes
  Supabase auth modules from `apps/web` entirely and hard-requires
  `ZITADEL_CLIENT_ID` (`oidc-client.ts`, `requireEnv`).
- **Live probe (this revision), not inference:** `curl -s -o /dev/null -w
'%{http_code}' https://rolodex.fleetworks.dev/login` → `200`; response
  body contains `SUPABASE`/`Sign in`. **Production is currently still
  serving the pre-cutover Supabase login — login is NOT currently broken.**
  Round 1's Critic review concluded otherwise from deploy-config analysis
  alone, without a fresh live probe; that conclusion is superseded by this
  check.
- **The real risk was a not-yet-triggered trapdoor, not a live outage:**
  `render.yaml` (`autoDeploy: true`, `branch: main`) and
  `apps/web/vercel.json` (`deploymentEnabled.main`, previously `true`) would
  auto-deploy the merged cutover the moment any future push touched
  `apps/web`/`packages`/the lockfile — `vercel.json`'s `ignoreCommand` only
  happened to skip the last few (docs-only) pushes. **This has been
  disarmed** (`apps/web/vercel.json` → `deploymentEnabled.main: false`,
  `cb7a3fc`, pushed) as an out-of-band safety action before this revision,
  independent of whether this plan is ultimately approved. **Render's
  `render.yaml:22` says `autoDeploy: true`, but the deployed API does not
  match that claim.** Live probe: `POST /internal/testing/zitadel-session`
  (added by `dcf5d10`, on `origin/main`) → `404`, while
  `POST /internal/testing/magic-link` (an older, still-present route) →
  `401` (drain-token-gated, exists). `testingRoutes` is mounted
  unconditionally at `apps/api/src/index.ts:124`, so a `404` means the
  route isn't in the deployed build, not that it's env-gated — **the
  running API predates `dcf5d10`, and Render has not deployed `cb7a3fc`,
  `765e8af`, or `7d9324d` either**, despite all being on `origin/main` and
  `render.yaml` declaring no `buildFilter`. Why (dashboard autoDeploy
  actually off despite the blueprint, silently failing builds, or the
  service not tracking `main`) is unconfirmed — this plan does not assert
  a reason, only the observed fact. The residual questions (migration
  `0012`'s production-DB status, `@cogs/auth@0.6.0`'s audience-check
  compatibility with current Supabase tokens) are less urgent while the
  API isn't auto-deploying, but become a Phase 2 prerequisite the moment
  it starts again — resolving _why_ Render isn't deploying is on the user,
  outside this plan, before Phase 2's coordinated deploy is scheduled.

- Lighthouse needs **no new OIDC application** — `testing.ts:227` sets
  `clientId = process.env.AUTH_AUDIENCE`, the same client rolodex's regular
  web login uses (invariant documented at `testing.ts:221-226`). It needs a
  dedicated Zitadel user + two machine-user PATs
  (`ZITADEL_SEED_BOT_PAT`, `ZITADEL_LOGIN_CLIENT_PAT` — `testing.ts:66-72,231-232`).
  Its actual functional verification requires both the new client _and_ a
  deployed web+API on the new issuer/audience — it cannot run in Phase 1
  and is explicitly deferred to Phase 2.

### Freeze exit trigger

`apps/web/vercel.json`'s `deploymentEnabled.main: false` is not indefinite.
It is re-enabled as part of Phase 2's kickoff (the coordinated web+API
deploy, existing runbook steps 7-8) — that is the named trigger, not "when
someone remembers." A discoverable note was added to
`rolodex/docs/sessions/2026-08-25-web-zitadel-cutover/FOLLOWUPS.md` and
cross-referenced from `rolodex/docs/RENDER-RUNBOOK.md` (which already
documents `autoDeploy` behavior and is where a stranger hitting a frozen
deploy is more likely to look than a dated session dossier), so an
engineer who hits the disabled deploy later has a pointer to why and what
re-enables it, rather than this plan file being the only record.

## RALPLAN-DR Summary

### Principles

1. Registering new OIDC clients (additive, reversible, no code deploy) must
   not be bundled with real-account migration and a coordinated two-service
   redeploy (much higher blast radius) — separate go/no-go per risk tier.
2. Durable production Zitadel config changes go through the existing
   Terraform IaC (`zitadel.tf`) as a reviewable, scoped diff — not ad-hoc
   console clicks or scripts, **except** where a documented, reasoned
   exception applies (see Lighthouse PATs, open question below).
3. The existing `rolodex` (Supabase) client must not be modified or removed
   — it is necessary for rollback, though (correction from round 1) not
   sufficient by itself for the web side, which requires a code revert too.
4. New clients' shape is derived from **rolodex's actual production
   architecture**, not transcribed from the local dev seed. `rolodex_web` is
   a server-side backend-for-frontend (`apps/web/src/app/auth/callback/route.ts`
   runs the PKCE exchange in Node, not browser JS) → `app_type =
OIDC_APP_TYPE_WEB`, matching all 5 existing apps. `rolodex_mobile` is a
   genuine native client → `app_type = OIDC_APP_TYPE_NATIVE`. Both are
   registered public (no client secret,
   `auth_method_type = OIDC_AUTH_METHOD_TYPE_NONE`) — this is a _deliberate_
   choice for `rolodex_web`, not a forced one: a Node route handler could
   hold a secret and go confidential (`WEB` + `BASIC`) instead. **Decided:
   public** (see Open Questions for the rationale) — not inherited from
   `oidc-client.ts`'s current `client.None()`, since the code does that
   _because_ the plan says public; the code can't be the plan's own
   justification for staying public. `access_token_type =
OIDC_TOKEN_TYPE_JWT`, with the full grant/response type set proven locally
   (`fleetworks-monorepo/infra/zitadel-local/seed.ts:283-296`) — the local
   seed's own `app_type` default (`USER_AGENT`, a port-derived convenience
   default for all 5 web apps) does **not** carry over; it was checked
   against the real code and found to not apply.
5. Every new client is verified with a real, standalone protocol round trip
   (dedicated test account, direct HTTP calls, no dependency on any
   deployed app) before Phase 2 depends on it.

### Decision Drivers (top 3)

1. **Blast-radius separation that survives contact with the real deploy
   config** — not just "additive vs. destructive" in the abstract, but
   checked against what `render.yaml`/`vercel.json` actually do today.
2. **IaC consistency, scoped narrowly** — route through `zitadel.tf`, but
   with `-target` and a named abort-list, since the root also owns
   fleetworks.dev DNS and SES/SMTP.
3. **Credential minimization** — the Lighthouse PATs must be dedicated,
   narrowly-scoped machine users, not the org-wide `terraform` IAM_OWNER key
   or the shared login-client PAT that powers every app's hosted login UI.

### Viable Options

**Option A — Single combined pass.** Provision clients and immediately run
the full runbook (real-account migration + coordinated web/API deploy) in
one continuous session.

- Pros: fastest to fully-live; closes the "armed trapdoor" window fastest
  (moot now — Phase 0 already closed it independently of which option wins).
- Cons: collapses additive config change and real-user-data mutation into
  one approval; still true even after Phase 0, since account migration and
  coordinated deploy remain the higher-risk operations regardless of
  trapdoor status.

**Option B — Two gated phases (favored).**

- Phase 1 (this plan): Terraform-provisioned clients + Lighthouse
  user/PATs; standalone protocol verification only; zero app deploys, zero
  account mutation.
- Phase 2 (separate approval): existing runbook steps 2-11 — real account
  list, backup, `zitadel_subject` migration, maintenance window, coordinated
  deploy, Lighthouse's actual functional verification, smoke test, rollback.
- Pros: matches the user's explicit "separately and deliberately" framing;
  proves the clients work via direct protocol calls before any account or
  deploy risk; small, targeted Terraform diff.
- Cons: two sessions instead of one; the runbook's near-zero-real-users
  fact (2-3 accounts) means Option C below may be nearly as safe and
  faster.

**Option C — Register clients + restore login now, defer only account
migration** (added this revision, per Critic's fairness finding). Provision
the clients (Phase 1 as in Option B), then immediately proceed through
env-var wiring and a coordinated web+API deploy to restore production login
on the new Zitadel clients — but explicitly _skip_ the `zitadel_subject`
backfill script, since with only 2-3 real accounts and login currently
intact (not urgent), that migration can follow within the same maintenance
window or shortly after without extending user-facing risk.

- Pros: production stays on a single, current, supported auth path sooner;
  avoids a second deploy window later; the account list/backfill is small
  enough that deferring only it (not the whole deploy) is plausible.
- Cons: still bundles "prove the client works" and "deploy real auth
  cutover to production" into one session, which is exactly what Principle
  1 exists to avoid — three consecutive review rounds this session found
  wrong-but-legal client configurations invisible to a protocol round trip,
  and Option C would carry that same unverified-classification risk
  straight into a real production deploy, in the same session as writing
  the Terraform. This is Option C's real cost even assuming the deploy
  _is_ deliberately scheduled and the 2-3 real accounts _are_ notified
  per runbook steps 2/7 (nothing about Option C itself implies otherwise —
  it pays the same coordination cost Option B pays, once instead of twice).
  The tradeoff is genuinely: one coordinated window vs. two, against
  Principle 1's bundling objection — not a claim that Option C is run
  carelessly.

**Recommendation: Option B**, for the reasons in the Decision Drivers.
Three review rounds this session each found a wrong-but-legal client
configuration Phase 1's own gate couldn't detect — but that detection came
from _reviewing the plan_, not from _phase isolation_, and Option C gets
the identical review pass, so this isn't an argument for B over C by
itself. The isolation-specific argument that does hold: a client nothing
yet depends on is cheap to destroy and recreate if a classification error
surfaces later, with no users, no window, and no rollback involved — that
benefit is real and is what Option C gives up by deploying against the new
client in the same session it's created. Option C remains a real,
fairly-costed alternative (one coordinated window instead of two), not a
strawman — flagged for the user to weigh explicitly, with the freeze
duration (below) counted as part of Option B's price.

### Pre-mortem (4 scenarios)

1. **Terraform apply touches the shared root's other resources** —
   `zitadel_application_oidc.app["rolodex"]` (the rollback fixture),
   `zitadel_project.fleetworks_suite` (pulled in as a dependency by
   `-target`, since both new apps reference its `id`; governs all 5
   existing apps' token/branding settings), `zitadel_email_provider_smtp.ses`
   (documented projection-wedging bug, breaks transactional email
   fleet-wide), `aws_iam_access_key.ses`, `zitadel_default_login_policy`/`_label_policy`.
   _Mitigation:_
   `terraform plan -target=zitadel_application_oidc.rolodex_web
-target=zitadel_application_oidc.rolodex_mobile`, plus a full untargeted
   `plan` read for information with an explicit **abort-and-escalate rule**
   naming all six resources (the SMTP resource included, with an
   attribute-scoped carve-out for its write-only `password` — see AC#1) —
   any diff outside that carve-out stops everything before apply.
2. **`ZITADEL_LOGIN_CLIENT_PAT` given to `apps/api` is the same PAT that
   powers the shared hosted Login V2 UI for every Fleetworks app**
   (`infra/zitadel-login-client.pat`) — a compromised rolodex API could
   complete arbitrary login flows fleet-wide. _Mitigation:_ investigate
   whether Zitadel's `IAM_LOGIN_CLIENT` role can be granted to a second,
   dedicated machine user before setting this Render secret; escalate to
   the user as a named, accepted risk if Zitadel genuinely requires reuse.
3. **The Lighthouse _or_ `phase1-verify` Zitadel user/password becomes a
   standing takeover primitive** — either is a real credential on the
   production identity provider. Lighthouse's account is intentionally
   long-lived (CI needs it repeatedly) behind the drain-token gate
   (`testing.ts:19-28,209-218`); `phase1-verify` has no such ongoing
   purpose once Step 7 completes. _Mitigation:_ both get generated
   passwords in the same gitignored storage as `zitadel-admin-password.txt`.
   For `phase1-verify` specifically: delete it after Step 7's verification
   succeeds, unless it's deliberately retained for Phase 2 re-verification
   — that choice is made explicitly (see AC), not left as an indefinitely
   standing, unowned credential. For Lighthouse: before Phase 2's
   verification is considered done, re-confirm the drain-token gate is live
   in the deployed environment.

4. **A wrong-but-legal `app_type`/`auth_method_type` combination is
   registered and silently works.** This is exactly what almost happened
   this round — `USER_AGENT` + `NONE` + PKCE is a legal Zitadel combination
   that would have passed every protocol round trip in this plan, while
   permanently mis-declaring a server-side client as browser-public and
   foreclosing a confidential-client option nobody deliberately gave up.
   _Mitigation:_ `app_type` is derived from reading the actual token-exchange
   code (Principle 4), not copied from a fixture; the protocol round trip is
   explicitly named as _evidence the flow works_, not evidence the
   _classification_ is correct — those are checked separately, before the
   Terraform resource is written, not after.

_(Round 1's pre-mortem missed the actually-relevant risk — an armed but
not-yet-fired auto-deploy trapdoor. That is no longer a pre-mortem item
because it has already been resolved via Phase 0, not because it wasn't
real.)_

### Expanded Test Plan

- **Unit:** none new — no application code changes in Phase 1.
- **Integration:** standalone PKCE round trip against `id.fleetworks.dev`
  using the new `rolodex_web` client_id and a dedicated test account — full
  authorize → real login → code exchange → JWT access token → **refresh
  grant** (the refresh grant was tested locally this session; Phase 1 must
  prove it in production too, since `apps/web`'s `oidc-client.ts` and
  mobile's `fleetworks-oauth.ts` both depend on it). Repeat the authorize→
  token round trip for `rolodex_mobile` with its native redirect URI.
- **E2E:** explicitly **not** run in Phase 1 (round 1's mistake). Lighthouse's
  real functional check (`/internal/testing/zitadel-session` →
  `/auth/testing-session`) requires the API's `AUTH_ISSUER`/`AUTH_AUDIENCE`
  repointed to Zitadel, which is a global auth cutover for the API, not a
  test-scoped change — that belongs to Phase 2, alongside the coordinated
  deploy it's actually testing.
- **Observability:** check Fly logs for `fleetworks-zitadel` during
  verification for the new clients' `CreateSession`/token calls — confirm
  no unexpected errors, calls attributable to the intended test accounts.

## Acceptance Criteria (testable)

- [ ] Before any resource is added, capture the full untargeted
      `terraform plan` output as a **recorded baseline**. Then
      `terraform plan -target=zitadel_application_oidc.rolodex_web
  -target=zitadel_application_oidc.rolodex_mobile` shows exactly those 2
      resources added, and a second full untargeted `plan` shows **no new
      diff versus the recorded baseline** for
      `zitadel_application_oidc.app["rolodex"]`, `zitadel_project.fleetworks_suite`
      (Terraform's `-target` pulls in a targeted resource's dependencies —
      both new apps reference `project_id = zitadel_project.fleetworks_suite.id`,
      so this project resource is necessarily included in the targeted
      apply; its settings, e.g. `project_role_assertion`/`private_labeling_setting`,
      govern all 5 existing apps' tokens and login branding, not just the
      2 new ones), `zitadel_email_provider_smtp.ses`, `aws_iam_access_key.ses`,
      `zitadel_default_login_policy`, `zitadel_default_label_policy` — with
      one **attribute-scoped** carve-out: a diff confined to
      `zitadel_email_provider_smtp.ses`'s write-only `password` attribute is
      expected and benign (write-only attributes aren't persisted in state,
      so it may show every plan regardless of this change); a diff touching
      **any other attribute** of that resource, or **any** attribute of the
      other five, aborts before apply. `terraform plan` reports per-attribute,
      so this is directly checkable, not a judgment call at apply time.
- [ ] `rolodex_web`: `app_type = OIDC_APP_TYPE_WEB` (verified against
      `apps/web/src/app/auth/callback/route.ts` — the PKCE exchange runs
      server-side in Node, not browser JS; **not** `USER_AGENT`),
      `redirect_uris = ["https://rolodex.fleetworks.dev/auth/callback"]`,
      `post_logout_redirect_uris = ["https://rolodex.fleetworks.dev/"]`,
      `response_types = ["OIDC_RESPONSE_TYPE_CODE"]`,
      `grant_types = ["OIDC_GRANT_TYPE_AUTHORIZATION_CODE", "OIDC_GRANT_TYPE_REFRESH_TOKEN"]`,
      `auth_method_type = OIDC_AUTH_METHOD_TYPE_NONE`,
      `access_token_type = OIDC_TOKEN_TYPE_JWT`, `dev_mode = false`,
      `id_token_userinfo_assertion` deliberately **omitted** (rolodex reads
      claims off the JWT directly; the Supabase-relying-party apps need it,
      this one doesn't).
- [ ] `rolodex_mobile`: `app_type = OIDC_APP_TYPE_NATIVE`,
      `redirect_uris = ["rolodex://auth/callback"]`,
      `post_logout_redirect_uris = ["rolodex://"]`, same
      response/grant/auth/token-type/`dev_mode` settings as above.
- [ ] A dedicated `phase1-verify` Zitadel test account exists — **separate**
      from the Lighthouse CI account created in a later criterion, so
      Lighthouse's account keeps a single, drain-token-gated purpose. Its
      password uses the same gitignored storage convention as
      `zitadel-admin-password.txt`. After Step 7's verification succeeds,
      either delete this account or explicitly record a decision to retain
      it for Phase 2 re-verification — it does not stay as a standing,
      unowned credential by default.
- [ ] Standalone authorize→code→token→refresh round trip against
      `id.fleetworks.dev` succeeds for `rolodex_web`, using the
      `phase1-verify` account (never a real user). On the **initial
      exchange**, the token response must contain **all three** of
      `access_token` (3-segment JWT), `id_token`, and `refresh_token` —
      matching exactly what `apps/web/src/app/auth/callback/route.ts:94-95`
      destructures and hard-requires (it fails the login if any one is
      missing). On the **refresh** leg, only `access_token` is required —
      matching `apps/web/src/app/api/session/route.ts:104-108`, which
      guards on `access_token` alone; an `id_token` on refresh is OPTIONAL
      per OIDC Core §12.2 and is consumed via `tokens.claims()` with
      optional chaining plus a `me.email`/`me.name` fallback
      (`api/session/route.ts:~118-130`) — graceful degradation, not a hard
      requirement, so its absence must not fail this criterion. Note:
      `https://rolodex.fleetworks.dev/auth/callback`
      is currently served by the _pre-cutover_ Supabase handler (`307`
      today) — capture `?code=` from the redirect before it's consumed;
      this is expected, not a failure.
- [ ] Standalone authorize→code→token round trip succeeds for
      `rolodex_mobile` with its native redirect URI, using the same
      `phase1-verify` account.
- [ ] A dedicated Lighthouse Zitadel user + `ZITADEL_SEED_BOT_PAT` +
      `ZITADEL_LOGIN_CLIENT_PAT` exist, with the login-client PAT's scope
      resolved per pre-mortem #2 (dedicated machine user, or an explicit,
      user-accepted risk note if Zitadel can't scope it narrower). **Not**
      tested end-to-end in Phase 1 — that's Phase 2.
- [ ] `zitadel_application_oidc.app["rolodex"]` (Supabase) unchanged, and
      its `client_id`/`client_secret` are independently backed up (Step 4a)
      before `terraform apply` runs — not just planned, actually done.
- [ ] No change to `apps/web`/`apps/api` production env vars, no deploy of
      either, no mutation of the rolodex `users` table. `apps/web/vercel.json`'s
      `deploymentEnabled.main` stays `false` until Phase 2 deliberately
      re-enables it as part of the coordinated deploy.

## Implementation Steps

0. **(Done, this revision.)** Disarmed Vercel auto-deploy on `main`
   (`apps/web/vercel.json`, `cb7a3fc`, pushed) so no unrelated future push
   can silently ship the already-merged Zitadel-only cutover.
   0a. Capture the full untargeted `terraform plan` baseline (see AC#1) before
   touching anything.
1. `fleetworks-web/infra/zitadel.tf` — add
   `resource "zitadel_application_oidc" "rolodex_web"` (`app_type =
OIDC_APP_TYPE_WEB` — derived from `apps/web/src/app/auth/callback/route.ts`'s
   server-side token exchange, not copied from the local seed's SPA-shaped
   default) and `"rolodex_mobile"` (`app_type = OIDC_APP_TYPE_NATIVE`),
   translating the rest of the proven-locally shape
   (`fleetworks-monorepo/infra/zitadel-local/seed.ts:62-93,283-296`) into
   HCL — `response_types`/`grant_types` with the refresh grant, and
   `dev_mode = false` (both existing resources set this explicitly at
   `zitadel.tf:64,100` "must stay false in production" — local's
   `developmentMode: true` does not translate). Omit
   `id_token_userinfo_assertion` for both (see AC).
2. Add a client-id-only output for the two new resources (public clients,
   no `client_secret`).
3. Use `~/.local/bin/terraform-1.15.8` (per `versions.tf`'s comment — the
   Homebrew `terraform` formula is frozen at 1.5.7 and hard-errors on this
   root's write-only SMTP attribute). Confirm AWS/Cloudflare credentials and
   `TF_VAR_zitadel_org_id` are set, and `infra/zitadel-provider-key.json`
   is present, before running anything.
4. `terraform plan -target=...` for the 2 new resources; separately, a full
   `terraform plan` read for information, compared against the step-0a
   baseline per the abort-list above.
   4a. **Before apply:** independently capture the existing `rolodex` (Supabase)
   client's `client_id`/`client_secret` (via `terraform state show
 'zitadel_application_oidc.app["rolodex"]'` or the Zitadel console) into
   the same gitignored-secret storage as `zitadel-admin-password.txt` —
   a backup independent of Terraform state itself, per pre-mortem #1's
   mitigation and Principle 3's rollback requirement. Not just a
   risks-table note: this step must actually run before step 5.
5. `terraform apply -target=...` (execution-phase action, not taken during
   planning) — creates the 2 new clients.
6. Provision the `phase1-verify` Zitadel test account (separate from
   Lighthouse's). Resolve pre-mortem #2 (login-client PAT scoping) — confirm
   whether Zitadel's `zitadel/zitadel ~> 3.3` provider (or the Management
   API directly) supports a dedicated `IAM_LOGIN_CLIENT`-scoped machine user
   distinct from the shared one; escalate as a named risk if not. Then
   provision the Lighthouse Zitadel user + 2 machine PATs via
   `fleetworks-web/scripts/zitadel-api.mjs` (IAM_OWNER break-glass) or the
   console — concrete endpoints/payloads (`CreateUser`, `CreateMachineUser`,
   PAT creation) to be written out at execution time once this step's
   scoping question is resolved, not assumed here. Store the PATs in the
   same gitignored-file convention as `zitadel-admin-password.txt`;
   rotation policy for these PATs is an open question (below) — not
   automated yet.
7. Run the standalone verification (Expanded Test Plan's Integration
   section) using the `phase1-verify` account — web and mobile round trips,
   direct HTTP calls, no deployed app involved. Remember: the web round
   trip's redirect still lands on the _pre-cutover_ Supabase callback
   handler (`307` today) — capture `?code=` before it's consumed.
8. **Stop.** No env var changes on Render/Vercel/EAS, no deploys, no
   account migration, no Lighthouse functional test. All of that is Phase 2
   — the existing runbook, requiring its own separate, explicit approval.
   This plan does not change Render's configuration; resolving _why_
   Render isn't actually deploying `main` (see Ground Truth) is a Phase 2
   prerequisite, not something Phase 1 fixes.

## Risks and Mitigations

| Risk                                                                                                                                                                                   | Mitigation                                                                                                                                                                                                                                                                                              |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Terraform apply drifts/touches the shared root's DNS/SES/SMTP/policy resources                                                                                                         | `-target` for the 2 new resources; full-plan read with a named abort-list; independent backup of the existing `rolodex` client's id/secret before apply                                                                                                                                                 |
| Over-privileged PAT reuse for Lighthouse (shared login-client identity)                                                                                                                | Investigate a dedicated scoped machine user first; escalate as an accepted risk if Zitadel can't scope it narrower                                                                                                                                                                                      |
| Lighthouse or `phase1-verify` test account becomes a standing takeover vector                                                                                                          | Generated passwords for both, gitignored storage; Lighthouse's drain-token gate re-verified live in Phase 2; `phase1-verify` deleted after Step 7 or explicitly retained by decision, never left standing by default                                                                                    |
| Phase 1 quietly expands into deploys/account migration                                                                                                                                 | Explicit stop/checkpoint acceptance criterion; Phase 2 requires its own separate approval; `deploymentEnabled.main` stays `false` until then                                                                                                                                                            |
| Web rollback assumed to be a simple env flip (it isn't — Supabase auth code is deleted)                                                                                                | Rollback plan for Phase 2 explicitly specifies `git revert` + redeploy for web, env flip for API                                                                                                                                                                                                        |
| A wrong-but-legal `app_type` is registered and silently works (pre-mortem #4)                                                                                                          | `app_type` derived from reading the actual token-exchange code, not copied from the local seed; protocol round trip treated as evidence the flow works, not evidence the classification is right                                                                                                        |
| Render's blueprint says `autoDeploy: true`, but a live probe shows the deployed API predates `dcf5d10` — it is not actually deploying from `main` right now, for an unconfirmed reason | Recorded as an observed fact, not assumed safe from the config; user is resolving _why_ Render isn't deploying, and independently checking migration `0012`'s prod status and `@cogs/auth@0.6.0` token compatibility, before Phase 2 schedules a deploy that would rely on Render tracking `main` again |

## Verification Steps

`terraform plan` diff review (scoped + abort-list) → standalone PKCE round
trips (web + mobile, including refresh grant) → Fly log check for the new
clients' auth calls. No Lighthouse/E2E check in Phase 1 (see Expanded Test
Plan).

## Out of scope (Phase 2, existing runbook)

`rolodex/.omc/plans/zitadel-sso-phase1-cutover.md`, "Cutover runbook"
section, steps 2-11: real account list, backup, `zitadel_subject` migration,
maintenance window, coordinated web+API deploy (including re-enabling
`deploymentEnabled.main`), Lighthouse's actual functional verification,
smoke test, rollback (rewritten per this revision: web = git revert +
redeploy, API = env flip). This plan does not start or schedule Phase 2.

## Open questions (unresolved, flagged rather than assumed)

- Does `zitadel/zitadel ~> 3.3` expose `zitadel_machine_user`/
  `zitadel_personal_access_token` resources? Determines whether the
  Lighthouse machine users belong in Terraform (Principle 2, no exception
  needed) or are a documented, reasoned exception to it.
- Can a second `IAM_LOGIN_CLIENT`-scoped machine user be created distinct
  from the shared one, or does Zitadel require reuse of the single
  instance-wide login-client identity?
- Does the Lighthouse test user need a corresponding rolodex `users` row
  with `zitadel_subject` set, or does JIT provisioning cover it? — affects
  Phase 2's Lighthouse verification, not Phase 1.
- PAT rotation policy — none exists yet for these two PATs; acceptable to
  leave manual for now, but should be named explicitly rather than silently
  absent.
- ~~`rolodex_web` public vs. confidential~~ — **decided, not deferred.**
  The exchange runs server-side (`apps/web/src/app/auth/callback/route.ts`),
  so a confidential client (`WEB` + `BASIC`, secret in Vercel env) was
  technically available and strictly stronger than public+PKCE — but the
  user was asked directly and chose **public** (PKCE, no secret): simpler,
  no secret to provision or rotate, no `apps/web` change needed, and
  matches what `oidc-client.ts` already implements. Registered as
  `auth_method_type = OIDC_AUTH_METHOD_TYPE_NONE` in AC#2/Step 1 — this is
  final for Phase 1, not a placeholder. (The reason this was worth deciding
  now rather than deferring: AC#4/#5's round trips verify this specific
  `client_id`, and a later switch to confidential would mean either
  mutating `auth_method_type` on a live client or recreating it with a new
  `client_id` — either invalidates Phase 1's own verification.)

## ADR: Scope this plan to client registration + standalone verification only

**Decision:** Register two new production Zitadel OIDC clients
(`rolodex_web`, `rolodex_mobile`) via Terraform, plus a Lighthouse test
user and machine PATs, verify them with standalone protocol round trips
against dedicated test accounts — and explicitly stop there. Real-account
migration and the coordinated web+API deploy (existing runbook steps
2-11) are a separate phase requiring its own future approval.

**Drivers:**

1. Blast-radius separation that survives contact with the real deploy
   config, not just in the abstract.
2. IaC consistency, scoped narrowly (Terraform, `-target`, a checkable
   abort-list) given the shared root also owns fleetworks.dev DNS and
   SES/SMTP.
3. Credential minimization for the two new Lighthouse PATs.
4. A demonstrated pattern this session: three review rounds each found a
   wrong-but-legal client configuration (`app_type`, an `id_token`
   assertion, in both directions) invisible to a protocol round trip —
   review catches these, not phase isolation, but a client nothing yet
   depends on is cheap to destroy and recreate if one surfaces after
   registration.

**Alternatives considered:**

- **Option A — single combined pass** (register + full runbook in one
  session). Rejected as favored: collapses an additive config change and
  real-user-data mutation into one approval, contrary to the user's own
  "separately and deliberately" framing.
- **Option C — register + restore login now, defer only account
  migration.** A real, fairly-costed alternative, not a strawman: one
  coordinated window instead of two, at the cost of deploying against a
  freshly-registered, not-yet-independently-exercised client in the same
  session it's created. Not chosen, but presented to the user as a
  legitimate option alongside B, with the freeze's duration (below)
  counted honestly as part of B's price.

**Why chosen (Option B):** Matches the explicit request; isolates the
higher-risk, harder-to-reverse operations (real accounts, coordinated
deploy) behind their own gate; and — narrowly, per the round-4 correction
to this plan's own reasoning — makes a later-discovered classification
error cheap to fix while nothing yet depends on the client.

**Consequences:**

- `apps/web/vercel.json`'s production deploy freeze (`deploymentEnabled.main: false`,
  `cb7a3fc`) persists until Phase 2's kickoff explicitly re-enables it —
  documented and cross-referenced (`765e8af`, `7d9324d`, `6a30db5`), not
  silently indefinite, but real until then.
- Render's actual deploy behavior is now known to disagree with its
  blueprint (`autoDeploy: true` claimed, `dcf5d10`-and-later not deployed)
  — resolving why is a Phase 2 prerequisite this plan surfaces but does
  not fix.
- `rolodex_web` is registered public (PKCE, no secret) as a final,
  user-confirmed decision for Phase 1 — not reopened by Phase 2 without a
  deliberate, separate reason to do so.
- The existing `zitadel_application_oidc.app["rolodex"]` (Supabase) client
  remains untouched and independently backed up (Step 4a) as the
  documented rollback fixture — necessary, not sufficient, for a full web
  rollback (which is `git revert` + redeploy, not an env flip).

**Follow-ups (Phase 2, not started by this plan):**

- Resolve why Render isn't deploying `main` before scheduling a
  coordinated deploy that assumes it will.
- Verify migration `0012_daily_orphan.sql`'s production-DB status and
  `@cogs/auth@0.6.0`'s token-audience-check compatibility with current
  Supabase tokens.
- Real account list, backup, `zitadel_subject` migration, scheduled
  maintenance window, coordinated web+API deploy (re-enabling
  `deploymentEnabled.main`), Lighthouse's actual functional verification,
  smoke test, rollback — per the existing runbook
  (`rolodex/.omc/plans/zitadel-sso-phase1-cutover.md`).
- Resolve whether `zitadel/zitadel ~> 3.3` exposes `zitadel_machine_user`/
  `zitadel_personal_access_token` (Terraform vs. documented script
  exception for the Lighthouse machine users), and whether a second
  `IAM_LOGIN_CLIENT`-scoped machine user is possible (pre-mortem #2).
