# Lessons

## Facts that were wrong in this repo's docs

- **Zitadel is not on Fly.** It moved to CapRover on app-02 on 2026-09-27 to 29 (hostinger `ansible/vars/services.yml`, entries `zitadel` and `zitadel-login`). This session told a peer the login app was on Fly and read Login v2 source at the Fly pin (v4.16.2) instead of the deployed tag (v4.17.3). Read hostinger `services.yml` first for anything about where Zitadel runs. Fixed by #30 and the memory note in #31.
- **`2cfc955` was not a direct push.** This session reported it as pushed to `main` without a PR; it arrived through PR #29 (merged 2026-11-20). Check `gh pr list --state merged` before calling a commit a direct push.

## Zitadel

- **Login v2 caches login settings in memory** per org, default 15 minutes (`API_CACHE_CONFIG`, `API_CACHE_ENABLED`; source `apps/login/src/lib/zitadel.ts` at v4.17.3). A policy change reached the hosted page about 13 minutes after the apply. A restart is a hostinger ansible run with `-e service_filter=zitadel-login` (owner call).
- The loginname page reads the policy of `organization ?? defaultOrganization`, so an org-level policy overrides the instance default.
- The text "Register new user" stays in the page payload as a translation string; check the `allowRegister` flag in the payload, not the text.
- Registration and other login-policy settings are enforced by the Login v2 app (pages, server actions), not by the v2 API calls it makes (source search, not tested live). Apps that build their own forms must re-implement the gating.
- An `ORG_OWNER` org key can create in-org users and grants (collectweave). Creating orgs needs the hub key.

## Process

- Verify ids a peer reports before storing them or minting keys: a read-only lookup with the hub key (org by name, machine user by user name with its resource owner) took seconds.
- Mint keys inside one script that never prints them: API -> 0600 template in a temp dir -> `op item create --template` -> delete the dir; delete the new key if the 1Password write fails; refuse to overwrite an existing item.
- The leak guard blocks `op item get --format json | jq` in Bash; read back field labels and lengths from a script instead.
- Two product sessions' shells (dont-panic, hullstock) defaulted to AWS account 392745011268 (`amplify-dev`); fleet work needs `AWS_PROFILE=workloom` (054772656652). Check `aws sts get-caller-identity` first.
- `dig` on this machine is broken (Homebrew `bind` missing `liburcu.8.dylib`); DNS over HTTPS (`curl` to `cloudflare-dns.com/dns-query` with `accept: application/dns-json`) worked.
- Many sessions asked this one for onboarding lessons it did not own (CI runners, ports, Supabase, CapRover, fastlane). Saying "unknown" and pointing at the owning session or file was the right answer; a shared onboarding source is still missing.
