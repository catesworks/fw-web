# Summary

## fw-web

- **#26 (`26aa9b3`), localweave and localweave-staff orgs.** Opened by this session on the owner's explicit go, approved by an independent read-only review, merged by the owner. sparky-localweave ran the scoped saved plan (6 to add) on the owner's instruction. This session verified the four ids against Zitadel (read-only), recorded them in 1Password `fw-web/zitadel-product-orgs/prod`, and minted keys into `fw-web/zitadel-localweave-terraform/prod` and `fw-web/zitadel-localweave-staff-terraform/prod` (expiry 2027-12-13). Orgs 399510326967533926 and 399510326917202278.
- **#27 (`41f640e`), dont-panic org,** opened, merged and applied (3 to add) by sparky-dont-panic. This session verified the ids, recorded them and minted `fw-web/zitadel-dont-panic-terraform/prod` (expiry 2027-12-14). Org 399512501395390822.
- **#14 applied.** hullstock-worker ran the scoped saved plan from the main checkout on the owner's go: 0 add, 1 change, 0 destroy; a refresh plan was clean. The hosted page kept showing Register for about 13 minutes (Login v2 login-settings cache), then `allowRegister:false`.
- **#28, #29 (dont-panic and rollkit From patterns), #22-#24 (uptimeloom, hullstock, pipeo):** merged by other sessions; zitadel-emails-worker reports all IAM applies done.
- **#30 (`75c6f42`):** status banner in `deploy/zitadel/README.md`, HISTORICAL headers on both `fly.toml`, corrected `GLOSSARY.md` and `CODING_STANDARDS.md`: Zitadel moved to CapRover app-02 on 2026-09-27 to 29.
- **#31 (`8969d6e`):** memory note `.claude/memory/reference_zitadel_hosting_app02.md`.
- 2026-11-28: pruned two dead worktree entries (`fw-linkweave`, `fw-formweave`; their directories were gone).

## Other repos

- **catesworks #2 (`d038d69`) and prospects #3 (`a5fee83`):** `CLAUDE.md` uses the per-machine root variables instead of hard-coded `/usr/local/repos/...` paths (the sparky checkouts live under `/Volumes/dev-ssd/repos`).
- **env-sync #56 (env-sync-worker):** agent-run prod commands section in the `secrets-crud` skill, with the owner's rule for agent-typed `y` and the infra-access token ruling.

## Calendar

Rotation and expiry reminders for every minted key: rollkit (2027-11-11 / 2027-12-11), localweave + localweave-staff (2027-11-13 / 2027-12-13), dont-panic (2027-11-14 / 2027-12-14); the earlier eight keys already had theirs.

## Checks (read-only)

- SES: all 11 identities `[true, SUCCESS, SUCCESS]` (zitadel-emails-worker); uptimeloom, rollkit, pipeo confirmed by their sessions; dont-panic and hullstock checked by this session under `AWS_PROFILE=workloom` (account 054772656652) because those sessions' shells were in another account.
- Hub DMARC: `v=DMARC1; p=quarantine; rua=mailto:<local>@fleetworks.dev; fo=1`; `fleetworks.dev` MX is Cloudflare Email Routing. Whether a routing rule exists for the local part: not verified.
- Login v2 source at v4.17.3: full route list, settings gating, and the v2 API methods it calls, sent to hullstock-worker.
