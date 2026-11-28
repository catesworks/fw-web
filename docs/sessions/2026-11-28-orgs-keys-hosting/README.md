# Session dossier: product orgs, keys, #14 apply and hosting docs (2026-11-12 to 2026-11-28)

Session `fw-web-worker` (bus name `anvil-fw-web`). Continues `docs/sessions/2026-11-11-orgs-register-sync/`. Created three more product orgs and minted their keys, saw the instance-default `allow_register = false` applied, corrected the stale Fly hosting docs, checked every product's SES identity, and answered many peer sessions.

## State in one paragraph

Done: orgs `localweave`, `localweave-staff` and `dont-panic` exist on `id.fleetworks.dev`, their ids are in 1Password `infra-access` item `fw-web/zitadel-product-orgs/prod`, and their org-scoped keys are minted (calendar reminders set). fw-web #14 is APPLIED (hullstock-worker ran the scoped saved plan; the hosted page shows `allowRegister:false` after the 15-minute Login v2 cache). The Fly hosting docs are marked as history (#30) and a memory note records that Zitadel runs on CapRover app-02 (#31). All 11 SES identities verify and all IAM From patterns are applied (zitadel-emails-worker). Nothing is mid-flight. Blocked on the owner: `og` Docker restart, formweave's retest, localweave's Register test, the hub DMARC routing rule.

## Repo state

| Repo | Branch / state | Last commit | Notes |
| --- | --- | --- | --- |
| `catesworks/fw-web` | `main` | `8969d6e` (#31) on 2026-11-24, before this dossier | No open PRs. Worktree `hullstock-from-pattern` belongs to hullstock. Two dead worktree entries pruned 2026-11-28. |
| `catesworks/catesworks` | `main` | `d038d69` (#2) | `CLAUDE.md` uses `$CATESWORKS_ROOT` / `$PERSONAL_ROOT`. |
| `catesworks/prospects` | `main` | `a5fee83` (#3) | `CLAUDE.md` uses `$PROSPECTS_ROOT` / `$CATESWORKS_ROOT`. |

Nothing applied from this session's own shell except read-only checks (Zitadel id lookups, SES `get-email-identity`, DNS over HTTPS). Key minting wrote only to 1Password and to Zitadel (machine keys).

## Resume prompt

> Resume the fw-web Zitadel hub work in /usr/local/repos/catesworks/fw-web. Read `docs/sessions/2026-11-28-orgs-keys-hosting/README.md` and `FOLLOWUPS.md`, then the 2026-11-11 dossier's `FOLLOWUPS.md`. State: localweave, localweave-staff and dont-panic orgs created and keyed; #14 applied; Fly docs marked history; all SES identities verified. Next: ask the owner whether the DMARC routing rule for the hub's rua address exists, and whether formweave's and localweave's registration tests have run.

## Read first

1. `FOLLOWUPS.md` (this dossier)
2. `LESSONS.md` (this dossier)
3. `.claude/memory/reference_zitadel_hosting_app02.md`
4. `docs/plans/zitadel-product-orgs.md` ("Adding one more org later")
5. `deploy/zitadel/README.md` (status banner)

## First action

Ask the owner whether a Cloudflare Email Routing rule exists for the local part of the hub's DMARC `rua` address at `fleetworks.dev` (see FOLLOWUPS).
