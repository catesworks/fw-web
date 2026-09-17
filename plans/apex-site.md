# Plan: fleetworks-web — apex marketing site for fleetworks.dev

**Status:** pending approval · **Mode:** direct · **Created:** 2026-07-23

**Scope:** new repo (`catesandrew/fleetworks-web`), Next.js App Router, deployed to Vercel, serving the root `fleetworks.dev` domain. 7 pages: home/hero, 5 dedicated app pages, 1 request-demo form. No API service, no Supabase, no render.yaml — pure Next.js on Vercel, consuming `@fleet-works/ui` + `@fleet-works/suite-nav` from npm.

## Context

This is the 6th app in the Fleetworks suite. The other 5 (chorus, helmsman, rolodex, warden, yellow-pages) are already live at their own `*.fleetworks.dev` subdomains, each wired with the shared `@fleet-works/ui` app switcher and design tokens (see sibling repos' recent commits). `fleetworks.dev` itself currently serves nothing — this plan fixes that.

Positioning (locked with user): unified control plane for org infra. Yellow Pages is the catalog/backbone — every service, team, account gets cataloged there. Rolodex is directory/access (users, groups, service accounts). Chorus is DNS (records/domains, reverse proxy/ingress entries). Helmsman is deployments/agents/CI orchestration, integrating with Chorus for ingress and Warden-managed infra. Warden is Terraform Cloud/cloud governance — workspace + AWS/Azure account management for the resources (services/lambdas/agents) the rest of the suite creates. Product is heading to public beta with live demos this weekend — copy needs to read as a real product pitch, not a personal project page.

## Grounded facts

- Suite app data (subdomain, accent color, description) already lives in `@fleet-works/suite-nav@0.1.0` (`suiteApps` export) — source of truth for per-app accent colors and URLs, don't hardcode a second copy.
- `@fleet-works/ui@0.1.1` exports `AppSwitcher`, `Logo`, `Footer`, and `tokens.css` (`--fw-*` custom properties) — same components already wired into all 5 sibling apps' topbars/footers.
- Each sibling app has real positioning copy already written in its own `README.md` and `PRODUCT.md` (all at repo root, e.g. `/Volumes/dev-ssd/repos/personal/chorus/README.md`) — pull from these rather than inventing new copy. `PRODUCT.md` in particular tends to carry the product-framing language (features, use cases) vs README's more technical framing.
- `fleetworks.dev` is already added to the Vercel team's zone (`team_n5vRyxj1deMvbBDZV2GQJLxr`), nameservers on Vercel DNS, verified — attaching it to a new Vercel project needs no manual DNS record (same auto-config behavior already used for the 5 subdomains).
- User decision: hero imagery, not real product screenshots (screenshots go stale fast during rapid development; the real product is a click away for beta users). No visual style locked in yet.
- User decision: demo form → Resend email notification only, no DB.

## Implementation Steps

### Phase 1 — repo scaffold

- `pnpm create next-app` (or hand-scaffold to match sibling conventions exactly) inside `fleetworks-web`: TypeScript strict, App Router, ESLint 9 + Prettier config copied from a sibling app (e.g. `warden/eslint.config.js`, `warden/prettier.config.js`) for consistency.
- Root `package.json`: name `fleetworks-web`, scripts `dev`/`build`/`typecheck`/`lint`/`format`.
- Add dependencies: `@fleet-works/ui@^0.1.1`, `@fleet-works/suite-nav@^0.1.0`, `resend`, `zod`.
- `apps/` structure: this repo is single-app (no api/mobile/desktop) — put the Next.js app at repo root (`src/app/...`), not nested under `apps/web/`, since there's no monorepo need here (no sibling api/mobile packages to separate from).
- `.env.example` documenting `RESEND_API_KEY` and `DEMO_REQUEST_TO_EMAIL`.
- `vercel.json` if needed (likely unnecessary — plain Next.js preset).
- Root layout (`src/app/layout.tsx`): import `@fleet-works/ui/tokens.css` + `globals.css`, render `<AppSwitcher currentId="fleetworks" />` in a shared header component and `<Footer appName="Fleetworks" accentColor="#111827" />` (the `fleetworks` entry's accent from suite-nav) in a shared footer, both wrapping all pages via the layout — so every page gets the suite switcher for free, no per-page wiring needed. Note: `suiteApps` in suite-nav already includes a `fleetworks` id entry (home) for exactly this.

### Phase 2 — content sourcing

- Read `README.md` + `PRODUCT.md` from each of the 5 sibling repos (`/Volumes/dev-ssd/repos/personal/{chorus,helmsman,rolodex,warden,yellow-pages}/{README.md,PRODUCT.md}`) and extract: one-sentence positioning, 3-4 concrete features, target user. Draft copy per app page from this material — don't invent claims the source docs don't support.
- Draft home page copy: the unified-control-plane narrative from Context above, plus a 5-tile overview linking to each app page (tiles pull name/description/accentColor live from `suiteApps`, not hardcoded).

### Phase 3 — visual exploration (impeccable live mode)

- Before building final page layouts, run `/impeccable live` on the home page hero section to generate and compare a few real hot-swapped visual directions in-browser (imagery style, hero layout, color treatment) — per the user's explicit preference for choosing visuals this way rather than picking one in advance. Accept/discard per the tool's normal flow. This determines the hero imagery treatment reused across all 5 app pages (each recolored to that app's accent), not a one-off per page.

### Phase 4 — page build (in order)

1. `/` — home: hero (from Phase 3's chosen direction), platform overview narrative, 5-tile app grid (data-driven from `suiteApps`), CTA to `/request-demo`.
2. `/chorus`, `/helmsman`, `/rolodex`, `/warden`, `/yellow-pages` — one shared page template (`src/app/[app]/page.tsx` style or 5 explicit route folders — prefer 5 explicit folders for clearer per-app content ownership over a dynamic route, since content differs enough that a dynamic template would need heavy per-app branching anyway) rendering: hero variant in that app's accent color, problem statement, feature list, target user, "Open {App}" link to its live subdomain (from `suiteApps.url`).
3. `/request-demo` — form UI (name, email, company, message; client-side validation mirrors the Zod schema).

### Phase 5 — demo form backend

- `src/app/api/demo-request/route.ts` — `POST` handler: parse + validate body with a Zod schema (name, email format, company, message), on success call Resend's API to send an email to `DEMO_REQUEST_TO_EMAIL` with the submission details, return `200`/`4xx` JSON accordingly. No database — Resend delivery is the only persistence.
- Manual step (user, not automatable from here): create a Resend account, verify a sending domain or use their sandbox sender, generate an API key, set `RESEND_API_KEY` + `DEMO_REQUEST_TO_EMAIL` in the Vercel project's environment variables.

### Phase 6 — deploy + DNS

- `gh repo create catesandrew/fleetworks-web --public --source=. --push` (matches the pattern used for `fleetworks-monorepo`).
- Connect the repo to a new Vercel project; attach `fleetworks.dev` (apex) as its custom domain via the Vercel API/dashboard (same auto-verify behavior seen when attaching the 5 subdomains, since the zone is already Vercel-managed) — also attach `www.fleetworks.dev` if desired, redirecting to apex.

## Acceptance Criteria (testable)

- [ ] `pnpm typecheck` and `pnpm build` both exit 0 with no errors.
- [ ] All 7 routes (`/`, `/chorus`, `/helmsman`, `/rolodex`, `/warden`, `/yellow-pages`, `/request-demo`) render without error in `next build`'s static/SSR output.
- [ ] `AppSwitcher` renders on every page (via root layout) and correctly highlights `fleetworks` as current; clicking any other suite app navigates to its real live subdomain URL (sourced from `suiteApps`, not hardcoded).
- [ ] Each app page's "Open {App}" link points at the exact URL in `suiteApps` for that app id (no typos/hardcoded drift from the canonical data).
- [ ] `POST /api/demo-request` with a valid payload returns `200` and (with real `RESEND_API_KEY` configured) triggers a real email; an invalid payload (missing name/malformed email) returns `400` with a validation error, never a 500.
- [ ] No real product screenshots used anywhere on the site — hero imagery only, per the user's explicit decision.
- [ ] `fleetworks.dev` resolves to the deployed Vercel project and serves the home page (verified post-deploy via a live HTTP request).

## Risks and Mitigations

| Risk                                                                     | Mitigation                                                                                                                                                                                           |
| ------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Copy invents unsupported product claims                                  | Draft only from each sibling's own README/PRODUCT.md; no speculative feature claims                                                                                                                  |
| Hero imagery picked without user sign-off                                | Phase 3 explicitly uses `/impeccable live` for in-browser comparison before committing to final page builds                                                                                          |
| Demo form silently drops submissions (Resend misconfigured/down)         | Route handler returns a clear error response (not a silent 200) if the Resend call fails; user is told in Phase 5 that `RESEND_API_KEY` setup is a manual prerequisite before the form is truly live |
| Suite switcher data drifts from source of truth                          | Home/app-page tiles and links read live from `@fleet-works/suite-nav`'s `suiteApps`, never a second hardcoded copy                                                                                   |
| npm package version drift (ui/suite-nav get new breaking versions later) | Pin `^0.1.1`/`^0.1.0` now; revisit if a future major bump changes the exported API                                                                                                                   |

## Verification Steps

1. `pnpm install && pnpm typecheck && pnpm build` — all clean, matches the verification bar used on the 5 sibling apps.
2. Local `pnpm dev`: manually click through all 7 routes, confirm `AppSwitcher` navigates correctly to each live subdomain, confirm `Footer` renders on every page.
3. Submit the demo form locally with `RESEND_API_KEY` set to a real sandbox key — confirm an email actually arrives; submit an invalid payload (bad email format) — confirm a `400` with a clear error, not a crash.
4. After deploy: `curl -I https://fleetworks.dev` returns `200`; visually load the home page and each app page in a browser to confirm hero imagery and copy render as expected.
5. Confirm no `docs/screenshots/*.png`-style real product images were copied into this repo (grep the repo for `.png`/`.jpg` under any imported-asset directory and manually confirm each is generated/illustrative, not a product screenshot).

## Open decisions deferred to implementation

- Exact visual direction for hero imagery — resolved live during Phase 3, not pre-decided here.
- Whether `/request-demo` also gets a `www.fleetworks.dev` → `fleetworks.dev` redirect, or both serve independently — default to redirect unless user says otherwise during Phase 6.
