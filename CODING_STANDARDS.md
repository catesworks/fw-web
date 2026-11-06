# Coding Standards

This document records the style and conventions this repo (`fw-web`, package `fleetworks-web`) already follows.
New contributions should follow these rules unless a section says otherwise.

Every rule here was derived from the tracked source and config. Where the repo is split, section 9 gives the counts, the majority convention, and the outliers.
Items marked **(aspirational)** are not yet true of the repo. They are listed so nobody mistakes them for current practice.

## 0. Scope

The repo holds two things that share one root:

| Area                          | Language / format            | Where                                                                                 |
| ----------------------------- | ---------------------------- | ------------------------------------------------------------------------------------- |
| Apex marketing site           | TypeScript, TSX, CSS Modules | `src/app/**`, `src/components/**`                                                     |
| Fleetworks identity hub (IaC) | Terraform (HCL)              | `infra/*.tf`                                                                          |
| Hub operational scripts       | Node.js ESM (`.mjs`)         | `scripts/*.mjs`                                                                       |
| Hub deploy config             | TOML                         | `deploy/zitadel/fly.toml`, `deploy/account/fly.toml`                                  |
| Docs, plans, ADRs, dossiers   | Markdown                     | `PRODUCT.md`, `DESIGN.md`, `docs/**`, `deploy/zitadel/README.md`                      |
| Repo config                   | JSON, YAML                   | `package.json`, `tsconfig.json`, `release-please-config.json`, `secrets.manifest.yml` |

There is no `CLAUDE.md`, `AGENTS.md`, or `.editorconfig` in this repo.
`.beads/**` is tool-managed (Beads issue tracker) and is out of scope.

## 1. General Code Style

- Favor clarity over brevity. Most files are short and flat: the largest TSX page is `src/app/request-demo/page.tsx` (198 lines).
- Derive suite data from `@fleet-works/suite-nav`, never from a second hardcoded list. `src/app/support/page.tsx` and `src/components/HeroVisual.tsx` both state this in comments, and every app page reads its `accentColor`, `name`, and `url` through `getSuiteApp()` / `otherSuiteApps()`.
- Take shared chrome from `@fleet-works/ui` (`AppSwitcher`, `Footer`, `tokens.css`). Do not restyle it locally (DESIGN.md, "Navigation").
- Follow `DESIGN.md` for visual decisions. Its named rules (One Light Rule, Earned Mono Rule, Schematic Rule) are binding on new pages.
- Remove unused variables and imports. The shared ESLint config errors on them; prefix an intentionally unused name with `_`.

## 2. Naming Conventions

| Item                                         | Convention                                   | Example (real path)                                                                                   |
| -------------------------------------------- | -------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| React components                             | `PascalCase` function                        | `HeroVisual` in `src/components/HeroVisual.tsx`                                                       |
| Route page components                        | `PascalCase` + `Page` suffix, default export | `WardenPage` in `src/app/warden/page.tsx`                                                             |
| Props interfaces                             | `PascalCase` + `Props`                       | `HeroVisualProps`                                                                                     |
| Functions, local variables, handlers         | `camelCase`; handlers `handleX`              | `requireSuiteApp`, `handleSubmit`, `handleChange`                                                     |
| Module-level literal constants / lookup data | `UPPER_SNAKE_CASE`                           | `HOME_APP`, `SHORT_LABEL`, `CENTER`, `CAPABILITIES`, `SUPPORT_EMAIL`                                  |
| Derived runtime values, schemas              | `camelCase`                                  | `demoRequestSchema`, `const here = path.dirname(...)` in scripts                                      |
| String-literal unions                        | `type` alias, `PascalCase`                   | `type SubmitStatus = 'idle' \| 'submitting' \| 'success' \| 'error'`                                  |
| Object shapes                                | `interface`, `PascalCase`                    | `interface FormState`                                                                                 |
| CSS Module classes                           | `camelCase` (or single lowercase word)       | `.btnPrimary`, `.appTileDot`, `.hero`                                                                 |
| Per-page CSS custom property for accent      | `--<app-id>-accent`                          | `--warden-accent`, `--home-accent`, `--hero-accent`                                                   |
| Route folders                                | `kebab-case`, matching the suite-nav id      | `src/app/yellow-pages/`, `src/app/helmsman/cloud-agents/`                                             |
| Scripts                                      | `kebab-case.mjs`                             | `scripts/hub-linking-smoke.mjs`                                                                       |
| Terraform files                              | `kebab-case.tf`, one concern per file        | `infra/zitadel-product-orgs.tf`, `infra/ses-alerts.tf`                                                |
| Terraform resources, variables, locals       | `snake_case`                                 | `zitadel_org.product`, `var.hub_identity_domain`, `local.dkim_records`                                |
| Docs (dated)                                 | `YYYY-MM-DD-<slug>`                          | `docs/sessions/2026-11-04-product-zitadel-orgs/`, `docs/superpowers/plans/2026-07-31-central-rbac.md` |
| ADRs                                         | `NNNN-<slug>.md`                             | `docs/sessions/2026-11-04-product-zitadel-orgs/adr/0001-central-product-orgs.md`                      |

Component file names are split. See section 9.

## 3. Formatting Rules

Formatting is owned by Prettier through `prettier.config.js`, which re-exports `@cogs/prettier-config` (`^0.2.0`). That shared config sets:

- `semi: true`: end statements with semicolons
- `singleQuote: true`: single quotes in TS/JS (JSX attributes keep double quotes, Prettier's default)
- `trailingComma: 'all'`
- `printWidth: 100`
- `tabWidth: 2`: 2 spaces, no tabs
- `arrowParens: 'always'`: `(app) => app.id`
- `endOfLine: 'lf'`
- `bracketSpacing: true`

Run `pnpm format` (writes) or `pnpm format:check` (verifies). Observed: all 1,345 indented TS/TSX/MJS lines use multiples of 2 spaces; 0 tabs; 0 double-quoted import specifiers (66 single).

Lines over 100 characters exist only where Prettier cannot break them, mostly long string literals: 7 in `src/app/helmsman/cloud-agents/page.tsx` (the `CAPABILITIES` copy), 2 in `HeroVisual.tsx`, 4 across scripts. Do not hand-wrap copy strings to dodge this.

### Braces and control flow

```ts
if (!parsed.success) {
  const message = parsed.error.issues[0]?.message ?? 'Invalid request.';
  return Response.json({ error: message }, { status: 400 });
}
```

- Return early on failure (route handler, `validate()` in `request-demo/page.tsx`, `requireSuiteApp`).
- Prefer `?.` and `??` over `&&` / `||` chains in TypeScript. The ESLint type-aware pass warns on `prefer-optional-chain` and `prefer-nullish-coalescing`. The `.mjs` scripts are not type-checked and use `process.env.X || 'default'`.

### Spacing

- One blank line between top-level declarations.
- Imports first, then a blank line (`import/first`, `import/newline-after-import` are errors).

### Terraform

- Formatted to `terraform fmt` style: 2-space indent, aligned `=` within a block.
- Constraint lives in `infra/versions.tf`: `required_version = ">= 1.11.0, < 2.0.0"`. The comment there explains why this root needs 1.11+ rather than the 1.5.x Homebrew build.

## 4. Comments and Documentation

The repo's dominant comment style explains _why_, often naming the incident or measurement behind the choice. Match it.

- **Why over what.** Examples: `src/app/global-error.tsx` ("Inline styles only: the layout's stylesheets are not guaranteed to load here."); `infra/dns.tf` (why every record is `proxied = false`); `deploy/account/fly.toml` (why `basePath` is `/ui/v2/login`).
- **JSDoc `/** \*/`** on exported components, props, and helper functions: `HeroVisual`, `HeroVisualProps`fields,`AppHeader`, `pentagonPoint`. 10 JSDoc blocks in total.
- **`//` line comments** for in-body notes and for short file headers in TSX: 40 occurrences.
- **Script headers.** Every `scripts/*.mjs` opens with a purpose comment and a `Usage:` line. Pick `/** */` for multi-paragraph headers (`hub-linking-smoke.mjs`, `register-fleetworks-provider.mjs`) or `//` for short ones (`zitadel-api.mjs`, `zitadel-system-api.mjs`).
- **Terraform** uses `#` comments only. Large files group sections with a ruled heading, e.g. `# ── Project + per-app OIDC clients ──` in `infra/zitadel.tf`, or `# --- DKIM: 3 CNAMEs per domain ---` in `infra/dns.tf`. Every one of the 12 variables and 28 outputs has a `description`. Descriptions say whether a value is a secret ("Not a secret; ...").
- **Safety-critical constraints are written in capitals** at the point of risk, e.g. `NEVER \`terraform apply\` this root unscoped` (`infra/zitadel-product-orgs.tf`) and `WITHOUT THIS, SELF-REGISTRATION SILENTLY SKIPS EMAIL VERIFICATION` (`deploy/account/fly.toml`). Keep this for genuine hazards only.
- **Copy entities in JSX.** JSX text uses HTML entities for typographic marks: `&mdash;` (31 uses), `&rsquo;`, `&ldquo;`/`&rdquo;`. JS string literals use the literal characters (`—`, `’`). See section 9 for the outliers.
- **No `TODO` / `FIXME` / `HACK` tags** exist in source today (0 found). Track follow-up work in Beads (`bd create`), not in code comments.

## 5. Error Handling

- **Validate at the trust boundary with Zod.** `src/app/api/demo-request/route.ts` parses JSON in its own `try`/`catch`, then `safeParse`s against `demoRequestSchema`, and returns the first issue's message with `400`.
- **Map failure classes to distinct HTTP statuses** with a user-safe `{ error: string }` body: `400` bad input, `503` missing server config, `502` upstream (Resend) failure. Success returns `{ ok: true }`.
- **Log server-side detail with `console.error`, never in the response.** The route logs which env var is missing, but the client only sees "not accepting submissions right now".
- **Fail loudly on broken invariants at module load.** `requireSuiteApp(id)` throws `Error('@fleet-works/suite-nav is missing its "<id>" entry')` rather than rendering an empty page.
- **Client forms** (`request-demo/page.tsx`): validate before `fetch`, track a `SubmitStatus` union, show errors in a `role="alert"` element, and catch network failure with a separate message.
- **Error boundaries** exist at both levels Next.js supports: `src/app/error.tsx` (segment, keeps header/footer) and `src/app/global-error.tsx` (renders its own `<html>`/`<body>`). Both are `'use client'`, take `reset`, and show the same copy.
- **Empty `catch {}`** is allowed (the shared ESLint config sets `no-empty` with `allowEmptyCatch`). Use it only for deliberate fallbacks, as in the JSON-parse fallback in `scripts/zitadel-api.mjs`.
- **CLI scripts** print usage with `console.error` and `process.exit(1)` when required arguments are missing (4 of 6 scripts take arguments; all 4 do this). They `throw` with a status-bearing message on failed API calls.
- **Terraform** guards destructive changes with `lifecycle { prevent_destroy = true }` (`zitadel_org.product`) and inputs with `validation` blocks (`var.hub_identity_domain`, `var.hub_records`). Mark credential inputs and outputs `sensitive = true`.

### Secrets

- No secret values in tracked files. `.gitignore` lists every credential file `infra/` may hold (`*.tfvars`, `*.tfstate`, `zitadel-provider-key.json`, password files). Add new ones there before creating them.
- App env vars are declared, empty, in `.env.example` with a comment per variable. The source of truth is 1Password, wired by `secrets.manifest.yml` (`app-secrets/fw-web/fleetworks-web` to Vercel production).
- Scripts read credentials from env vars or gitignored files at runtime. They never take a secret as a CLI argument that would land in shell history, except `hub-linking-smoke.mjs`, which takes a test user's password positionally.

## 6. Language-Specific Practices

### TypeScript and React (Next.js 15 App Router, React 19)

- `tsconfig.json` is `strict: true`, `noEmit`, `moduleResolution: "bundler"`, with the path alias `@/*` to `./src/*`. Import app modules through `@/` (`@/components/HeroVisual`); relative imports only for co-located CSS Modules (`./page.module.css`).
- **Type-only imports use `import type`**, as a separate statement (`@typescript-eslint/consistent-type-imports` with `separate-type-imports`). Inline `type` specifiers inside a value import are also used: `import { getSuiteApp, type SuiteApp } from '@fleet-works/suite-nav'`.
- Use primitive types (`string`, `number`), never boxed `String` / `Number`, and `unknown` for untrusted input (`let body: unknown` in the route). This matches the TypeScript handbook's "Do's and Don'ts".
- Server Components by default. Add `'use client'` only when the file needs state or event handlers: 3 files today (`error.tsx`, `global-error.tsx`, `request-demo/page.tsx`).
- Route handlers export named HTTP-method functions (`export async function POST(request: Request)`) and use the Web `Response.json`.
- Pages are `export default function XPage()`. Shared components are named exports (`export function HeroVisual`).
- Per-page accent: set one CSS custom property inline, cast once: `style={{ '--warden-accent': WARDEN_APP.accentColor } as CSSProperties}`. This is the only sanctioned inline style on app pages (One Light Rule).
- Lists rendered from suite data use `app.id` as `key`.
- Accessibility: decorative marks get `aria-hidden="true"`; SVG diagrams get `role="img"` plus a descriptive `aria-label` (`HeroVisual.tsx`, `helmsman/cloud-agents/page.tsx`). Form inputs pair `<label htmlFor>` with `id`. PRODUCT.md sets WCAG 2.1 AA as the floor.
- Metadata: `layout.tsx` sets `title.template: '%s · Fleetworks'`. Page-level `metadata.title` must be the bare page name (`'Cloud Agents'`). The template appends the brand.

### CSS (CSS Modules)

- One `page.module.css` per route, plus `status.module.css` shared by `error.tsx` and `not-found.tsx`, and `HeroVisual.module.css` beside its component. `globals.css` holds only `:root`, `*`, and `body` resets.
- Use `@fleet-works/ui` tokens (`var(--fw-color-ink)`, `var(--fw-space-4)`, `var(--fw-font-sans)`): 132 token references.
- Accent fallbacks use the apex accent: `var(--warden-accent, #111827)`.
- Fluid sizing with `clamp()` for headline type and page padding; one breakpoint style, `@media (max-width: 860px)`.
- No `box-shadow` anywhere (0 found), per DESIGN.md's Schematic Rule. Depth comes from 1px hairline borders and the Panel Surface tone.
- Hover transitions are short and single-property: `transition: background 0.2s ease`.
- Class naming is camelCase, not the hyphenated/BEM style that cssguidelin.es recommends. CSS Modules export classes as JS properties, so `styles.btnPrimary` beats `styles['btn-primary']`. Keep camelCase.

### Node.js scripts (`scripts/*.mjs`)

- ESM only (`"type": "module"` in `package.json`), top-level `await`, `node:`-prefixed built-ins (15 imports, 0 bare).
- Executable scripts start with `#!/usr/bin/env node` (4 of 6). The two Playwright scripts (`render-brand-logo.mjs`, `zitadel-bootstrap.mjs`) start with a comment that Playwright is not a dependency, then `// eslint-disable-next-line import/no-unresolved`.
- Resolve paths from the script, not the CWD: `const here = path.dirname(fileURLToPath(import.meta.url))`.
- Shared helpers are exported from a script and guarded for direct runs: `if (import.meta.url === \`file://${process.argv[1]}\`)`in`scripts/zitadel-api.mjs`. `hub-linking-smoke.mjs`imports`api` from it.
- Constants that configure a run (`DOMAIN`, `KEY_FILE`, `HUB`) are `UPPER_SNAKE_CASE` and env-overridable: `process.env.ZITADEL_DOMAIN || 'https://id.fleetworks.dev'`.
- Use native `fetch`. No HTTP client dependency.

### Terraform (`infra/`)

- One root, remote S3 + DynamoDB-lock backend with its own state key (`infra/backend.tf`). State holds secrets; the comment there says so.
- Providers pinned with `~>` in `infra/versions.tf`, with a comment for every non-obvious pin (Cloudflare v4, Zitadel 3.x).
- `for_each` over a `toset()` or map, with **static keys** that never depend on computed values (`"${domain}#${idx}"` in `infra/dns.tf`).
- Credentials enter as `sensitive = true` variables sourced from `TF_VAR_*`, never as defaults.
- Destructive or shared roots document the targeted-apply procedure in a plan doc (`docs/plans/zitadel-product-orgs.md`). Never run an unscoped `terraform apply` on `infra/zitadel-product-orgs.tf`.

### Markdown

- ATX headings (`#`), one H1 per file, tables for comparisons, fenced code blocks with a language tag.
- Plans and ADRs carry a **Status** line near the top (`docs/sessions/.../adr/0001-central-product-orgs.md`: `Status: accepted (owner, 2026-11-04)`).
- Claims about external systems are labelled measured vs. unverified (`docs/superpowers/plans/2026-07-31-central-rbac.md` §1.7, "NOT verified — do not size off these"). Keep that discipline.
- Session dossiers live in `docs/sessions/<date>-<slug>/` with `README.md`, `SUMMARY.md`, `LESSONS.md`, `FOLLOWUPS.md`, and `adr/`.
- Prettier formats Markdown too (`pnpm format` runs on `.`).

## 7. Commit and Review Practices

### Commits

- [Conventional Commits](https://www.conventionalcommits.org/) with a scope: 74 of the last 77 subjects match `type(scope): summary`. `release-please` (`.github/workflows/release-please.yml`) builds `CHANGELOG.md` and `vX.Y.Z` tags from them, so the type matters.
- Types in use: `feat`, `fix`, `docs`, `chore`, `ci`. `release-please-config.json` also maps `perf`, `refactor`, `test`, `build`. `chore` is hidden from the changelog.
- Common scopes: `rbac`, `infra`, `hub`, `zitadel`, `beads`, `sessions`, `web`, `scripts`, `secrets`.
- Summary is lowercase, imperative, no trailing period: `feat(infra): create product Zitadel orgs centrally (8 orgs + org-scoped terraform machine users) (#6)`. This differs from the agis git style guide, which asks for a capitalised summary under 50 characters. This repo's lowercase Conventional Commits form wins. Keep summaries short where you can; several existing ones exceed 72 characters.
- Append the PR number `(#N)` on squash merges and a Beads id in parentheses when the work tracks one: `fix(web): add missing error boundaries (fw-agp)`.

### Reviews

- Infra changes go through a PR, and an independent reviewer approves before the owner applies (`docs/sessions/2026-11-04-product-zitadel-orgs/SUMMARY.md`: PR #6, "approved after one round of fixes").
- Record non-trivial decisions as an ADR in the session dossier.
- Keep PRs to one concern. The infra PRs each add one file or one resource family.

## 8. Tests and Verification

- **There is no automated test suite.** No test runner, no `*.test.*` files, and no `test` script exist in `package.json`.
- Available static checks: `pnpm typecheck` (`tsc --noEmit`), `pnpm lint` (`eslint .` with `@cogs/eslint-config`, which includes `jsx-a11y`, `react-hooks`, and import hygiene), `pnpm format:check`.
- **(aspirational)** No CI workflow runs these checks; the only workflow is release-please. Run them locally before pushing.
- Hub behaviour is verified with operational smoke scripts against live systems, e.g. `scripts/hub-linking-smoke.mjs`, which the pilot plan calls "the correctness gate". Document the expected output when adding one.
- **(aspirational)** If a test runner is added, the shared ESLint config already relaxes rules for `**/__tests__/**` and `*.{test,spec}.*` (Vitest by default).

## 9. Inconsistencies Found

Counts are from tracked files at the time of writing. Source files were **not** edited; this section only reports.

| Category                            | Majority                                                                 | Outliers                                                                                                                                                                                                                         |
| ----------------------------------- | ------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Component file names                | none (1:1 split)                                                         | `src/components/HeroVisual.tsx` (PascalCase) vs `src/components/app-header.tsx` (kebab-case). Pick one for new components.                                                                                                       |
| Duplicated helper                   | n/a                                                                      | `requireSuiteApp()` is copy-pasted, identical, in 7 files: `src/app/page.tsx`, `chorus`, `helmsman`, `helmsman/cloud-agents`, `rolodex`, `warden`, `yellow-pages` `page.tsx`. Section 1 of the template prefers a shared helper. |
| Styling mechanism                   | CSS Modules (10 `.module.css` files)                                     | `src/app/request-demo/page.tsx` styles everything inline (16 `style={{` blocks, hardcoded `#B91C1C`). `src/components/app-header.tsx` also styles inline. `global-error.tsx` is inline by design (comment explains why).         |
| `CSSProperties` type reference      | `import type { CSSProperties } from 'react'` (7 files)                   | `HeroVisual.tsx` uses the global `React.CSSProperties`; `request-demo/page.tsx` uses global `React.ChangeEvent` while importing `SubmitEvent` by name in the same file.                                                          |
| Internal navigation                 | plain `<a href="/...">` (6 internal links)                               | `src/app/not-found.tsx` uses `next/link` `<Link>` (1).                                                                                                                                                                           |
| Page title vs layout template       | bare title (`'Cloud Agents'`)                                            | `src/app/support/page.tsx` sets `title: 'Support · Fleetworks'`. With the layout's `'%s · Fleetworks'` template this likely renders the brand twice.                                                                             |
| Page `metadata` coverage            | 7 of 9 page routes export no `metadata`                                  | Only `support` and `helmsman/cloud-agents` set it. The five app pages inherit the default title.                                                                                                                                 |
| Apostrophe in JSX text              | `&rsquo;` (5)                                                            | `&apos;` (2: `request-demo/page.tsx`, `support/page.tsx`).                                                                                                                                                                       |
| Em dash in JSX text                 | `&mdash;` (31)                                                           | Literal `—` in JSX text in `src/app/support/page.tsx` (2). Literal `—` in JS strings is the norm, not an outlier.                                                                                                                |
| Module-level constant case (`src/`) | `UPPER_SNAKE_CASE` for literal data                                      | `initialState` (`request-demo/page.tsx`) is a literal constant object in camelCase.                                                                                                                                              |
| Accent fallback color               | apex `#111827`                                                           | `helmsman/cloud-agents/page.module.css` and `page.tsx` mix `#2e62c9` (Helmsman blue) and `#111827` as fallbacks for the same `--helmsman-accent`.                                                                                |
| Script shebang                      | `#!/usr/bin/env node` (4 of 6)                                           | `render-brand-logo.mjs`, `zitadel-bootstrap.mjs` (Playwright one-offs, not meant to run as executables).                                                                                                                         |
| Commit subject format               | Conventional Commits (74 of 77)                                          | `add envrc`, `bd init: initialize beads issue tracking`, `infra(hub): ...` (`infra` is not a configured release-please type).                                                                                                    |
| Hosting comments in `infra/`        | Fly hosts `id.` (`infra/hub-dns.tf` line 12, `deploy/zitadel/README.md`) | `infra/hub-dns.tf` record `comment` still says `-> Render`, and `infra/dns.tf` line 6 says Render terminates TLS. Stale after the move to Fly.                                                                                   |

## 10. Tooling Reference

| Tool       | Config                                                                                     | Command                                                    |
| ---------- | ------------------------------------------------------------------------------------------ | ---------------------------------------------------------- |
| Prettier   | `prettier.config.js` re-exports `@cogs/prettier-config`                                    | `pnpm format`, `pnpm format:check`                         |
| ESLint 9   | `eslint.config.js` re-exports `@cogs/eslint-config` with `tsProjects: ['./tsconfig.json']` | `pnpm lint`, `pnpm lint:fix`                               |
| TypeScript | `tsconfig.json` (`strict`)                                                                 | `pnpm typecheck`                                           |
| Next.js    | `next.config.ts` (`reactStrictMode: true`)                                                 | `pnpm dev` (port 3000), `pnpm build`                       |
| Terraform  | `infra/versions.tf`                                                                        | `terraform fmt`, targeted `plan`/`apply` per `docs/plans/` |
| Release    | `release-please-config.json`, `.release-please-manifest.json`                              | runs on push to `main`                                     |
| Runtime    | `package.json` `engines`: Node `>=22`, pnpm `>=9`; `packageManager: pnpm@11.1.0`           | `pnpm install`                                             |

## 11. Changes to This Guide

Style evolves.
When the code and this document disagree, fix one of them in the same PR and say which in the commit body.
Shared formatting and lint rules live in `@cogs/prettier-config` and `@cogs/eslint-config`. Propose fleet-wide changes there, not here.
