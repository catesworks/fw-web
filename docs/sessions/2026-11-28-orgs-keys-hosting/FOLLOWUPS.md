# Follow-ups

## Blocked on the owner

1. Restart Docker/OrbStack on the CI runner `og`: two knowledge docker-release jobs hung for 30 minutes in `aws-actions/amazon-ecr-login` (reported by anvil-catesworks).
2. Hub DMARC: confirm a Cloudflare Email Routing rule exists for the local part of the `rua` address at `fleetworks.dev` (MX is Cloudflare Email Routing; without a rule, reports are dropped). Needed before moving `p=quarantine` to `p=reject`.
3. formweave's retest (registrar API signup plus refusal tests with an admin-created no-grant user) needs the owner's go in formweave's session; it creates production users.
4. localweave's hosted Register test: register a throwaway user with the org-id scope and confirm it lands in org `localweave` (policy applied, test not run).
5. Fix `dig` on this machine: `brew reinstall userspace-rcu bind` (not run).
6. Decide where a shared onboarding source lives (CI runner access, port allocation, Supabase, CapRover, ECR) so sessions stop asking fw-web-worker.

## Blocked on remaining work

1. End-to-end Zitadel mail still unconfirmed in the zitadel-emails worker log for collectweave, bookweave, hullstock, pipeo and LineOS-Staff.
2. localweave and localweave-staff have no domain or SES identity yet, so their mail uses the neutral sender.
3. Untested: whether `/register` refuses a direct visit with `allow_register = false`, and whether API user creation works with it off (formweave's retest is the first live case).
4. The knowledge service (anvil-claude-mods) is live on app-02; which Zitadel org it should use is still the owner's decision.
