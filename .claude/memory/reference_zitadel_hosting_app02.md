---
name: reference-zitadel-hosting-app02
description: "Zitadel (id.) and Login v2 (account.) run on CapRover app-02, not Fly; fw-web deploy/ Fly docs are history; where the real config lives"
metadata:
  node_type: memory
  type: reference
  originSessionId: 300f7397-a909-4daa-a4c8-ccaf3cf73d8c
  modified: 2026-11-24T22:08:51.845Z
---

Zitadel `id.fleetworks.dev` and Login v2 `account.fleetworks.dev` run on CapRover on app-02 (migrated from Fly.io 2026-09-27 to 2026-09-29; both Fly apps destroyed). Real config: hostinger `ansible/vars/services.yml`, entries `zitadel` (port 8080, `nginx_grpc_h2c`) and `zitadel-login` (port 3000), both `excluded_from_bulk_apps` (use `-e service_filter=<name>`); image tags `v4.17.3` as of 2026-11-24. Hostinger record: `.claude/memory/project_zitadel_cutover_live.md`, dossier `docs/sessions/2026-09-27-zitadel-cutover/`.

**Why:** I wrongly told a peer the login app was on Fly, because fw-web `deploy/zitadel/README.md`, `deploy/*/fly.toml`, GLOSSARY.md and CODING_STANDARDS.md still said so. I also analysed the Login v2 source at the wrong tag (v4.16.2 from `fly.toml`); the deployed tag was v4.17.3. Fixed in fw-web docs PR "docs: Zitadel runs on CapRover app-02, not Fly".

**How to apply:** for any question about where Zitadel runs, its image tag, restarts or env, read hostinger `services.yml` first, not fw-web `deploy/`. Login v2 caches getLoginSettings per org in memory for 15 minutes (API_CACHE_CONFIG / API_CACHE_ENABLED); a restart is a hostinger ansible run on `zitadel-login`, an owner call. See [[project-orgs-register-sync-2026-11]].
