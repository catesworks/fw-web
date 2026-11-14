# Fleetworks Web

This repo holds the Fleetworks apex marketing site at `fleetworks.dev` and the infrastructure for the Fleetworks identity hub: Zitadel config as Terraform, hub deploy config, and the plans for federating the suite's apps to it and centralising their roles. One glossary covers it, grouped by context.

## Language

### Fleetworks suite and apex site

**Fleetworks**:
The product suite: a unified control plane for an org's infrastructure, made of five apps plus the apex site.
_Avoid_: Fleet Works, FW (in prose); `@fleet-works` is only the npm scope

**Suite**:
The set of apps registered in `@fleet-works/suite-nav`, the one source for each app's id, name, URL, description and accent.
_Avoid_: platform, product family, a second hardcoded app list

**Apex site**:
The marketing site at `fleetworks.dev` that this repo builds (`src/app/`). It catalogs no infrastructure itself.
_Avoid_: home app, landing page, fleetworks-web (that is the package and Vercel project name), fw-web (the repo name)

**App**:
One of the five suite members, each with its own subdomain and its own Supabase project: **Yellow Pages**, **Rolodex**, **Chorus**, **Helmsman**, **Warden**.
_Avoid_: instrument (a DESIGN.md metaphor only), tool, module

**Yellow Pages**:
The **App** that is the authoritative service catalog of services, teams and cloud accounts; the backbone the other apps link back to. Served at `yp.fleetworks.dev`.
_Avoid_: catalog app, YP (except as the Hero Visual short label)

**Rolodex**:
The **App** that is the people directory: users, groups, service accounts and access grants, synced from Active Directory.
_Avoid_: directory app, RLDX

**Chorus**:
The **App** for DNS: an org's records and domains, who may change them, and what is safe to expose.
_Avoid_: DNS app, CHR

**Helmsman**:
The **App** for deployments and automation: applications, CI/CD pipelines, cluster deployments, and agents and multi-agent processes under one audit trail.
_Avoid_: deploy app, HLM

**Cloud agents**:
Helmsman's roadmap capability to define and govern one agent across AWS and Azure (`/helmsman/cloud-agents`).
_Avoid_: cross-cloud agents (as a product name)

**Warden**:
The **App** for cloud governance: the front door to Terraform Cloud workspaces and AWS/Azure accounts, with guarded writes and a deterministic config review.
_Avoid_: governance app, WRD

**Accent color**:
The one saturated brand color assigned to each **App** (and the apex) in `@fleet-works/suite-nav`, passed as `accentColor`.
_Avoid_: brand color, theme color, Signal Accent (DESIGN.md's display name for the same token)

**One Light Rule**:
The design rule that exactly one **Accent color** is live on any page, never mixed with a second saturated hue.
_Avoid_: single-accent rule

**Hero Visual**:
The shared hub-and-spoke diagram (`src/components/HeroVisual.tsx`) showing the five **Apps** around the control plane, with one active node lit in the page's **Accent color**.
_Avoid_: hero image, signal map

**Demo request**:
A visitor's name, email, optional company and message, submitted from `/request-demo` to `POST /api/demo-request` and emailed via Resend.
_Avoid_: lead, contact form, signup

### Identity hub

**Hub**:
The self-hosted Zitadel instance at `id.fleetworks.dev` that every **App** federates to; the upstream OIDC identity provider, not the session authority.
_Avoid_: auth hub, identity hub, account hub, IdP (when the Fleetworks one is meant)

**Account UI**:
The hub's branded login and signup UI at `account.fleetworks.dev`: the official `zitadel-login` (Login v2) image, branded at runtime from the instance label policy.
_Avoid_: login fork, account hub

**Relying party**:
An **App**'s Supabase project registered as an OIDC application inside the hub's Fleetworks Suite project, one per **App** so a leaked client secret is scoped to one product.
_Avoid_: OIDC client (except when quoting `zitadel_application_oidc`), tenant

**Fleetworks provider**:
The Custom OIDC provider with identifier `custom:fleetworks`, registered on each **App**'s Supabase project and pointing at the **Hub**. Users see it as "Sign in with Fleetworks".
_Avoid_: SAML SSO, generic OIDC, external provider

**Federation**:
Adding the **Fleetworks provider** to an **App** next to its existing password login, never replacing it.
_Avoid_: SSO (cross-subdomain session SSO is a separate sub-project), migration

**Dual-mode**:
The state of an **App** that offers both its own password login and "Sign in with Fleetworks".
_Avoid_: hybrid auth

**Account linking**:
Resolving a hub sign-in to the same Supabase `auth.users` row as an existing password account with the same verified email, giving that user two identities instead of a duplicate. `scripts/hub-linking-smoke.mjs` proves it.
_Avoid_: identity merge, auto-link (as a noun)

**Client surface**:
One of an **App**'s three front ends (web on Next.js, mobile on Expo, desktop on Tauri). All three share the **App**'s single Supabase project.
_Avoid_: client, platform

**Pilot**:
Phase 2 sub-project 1: standing up the **Hub** and federating **Yellow Pages** first, on web and mobile.
_Avoid_: POC, spike

**Sub-project**:
One of the six numbered parts of auth Phase 2: hub and pilot, roll-out to the other apps, session SSO, central RBAC, enterprise BYO-IdP, full account hub UI.
_Avoid_: phase (reserved for Phase 1/Phase 2 of auth, and the numbered phases inside the RBAC plan)

**Identity domain**:
An SES sending identity of the form `auth.<host>.fleetworks.dev` that hub mail is sent from. `auth.id.fleetworks.dev` is the hub's own.
_Avoid_: sending domain, mail domain

**Product org**:
A Zitadel org on the shared **Hub** instance for one product, created centrally in `infra/zitadel-product-orgs.tf` with `prevent_destroy`. The twelve today (bookweave, collectweave, dont-panic, formweave, hullstock, linkweave, localweave, localweave-staff, pipeo, pipeo-staff, rollkit, uptimeloom) are products outside the **Suite**.
_Avoid_: tenant, organization (unqualified)

**Org-scoped machine user**:
The `<org>-terraform` Zitadel machine user that holds `ORG_OWNER` on one **Product org** only, used by that product's repo to manage its own projects, apps and users.
_Avoid_: service account (a Rolodex term), bot

**Hub provider key**:
The JWT-profile key of the `terraform` machine user with instance `IAM_OWNER`, kept gitignored at `infra/zitadel-provider-key.json`. It authenticates the Zitadel Terraform provider and `scripts/zitadel-api.mjs`.
_Avoid_: admin token, PAT

### Central RBAC

**Fleetworks claim**:
The Rolodex-owned subtree at `app_metadata.fleetworks` on each Supabase user (`v`, `roles`, `source`, `syncedAt`): a replicated role cache that the **Apps** read.
_Avoid_: role claim, JWT roles, transport

**AuthRole**:
A role in the shared `@cogs/auth` tenant vocabulary, such as `org:contributor` or `org:viewer`. Only these appear in a **Fleetworks claim**.
_Avoid_: role (unqualified), permission

**Reconcile loop**:
The Rolodex process that diffs desired against actual grants per **Target** and is the sole writer of the **Fleetworks claim**. It replaces the `roles` array wholesale, never merging it.
_Avoid_: sync (that is the directory import from AD), push job

**Target**:
An external platform Rolodex reconciles grants into through a connector, with its own `config` and **Enforcement level**. The `fleetworks` connector has one target per Supabase project.
_Avoid_: destination, integration

**Binding**:
A Rolodex `access_bindings` row granting a role on a **Target** to a Rolodex group. It takes effect only once confirmed.
_Avoid_: grant (the per-user result of a binding), mapping

**Enforcement level**:
A **Target**'s setting for whether reconcile may revoke: `additive` (the default, grant only) or `full` (grants and revokes).
_Avoid_: mode, strictness

**Stale claim**:
A **Fleetworks claim** whose `syncedAt` is older than three reconcile periods, or that has no explicit offset. Readers ignore the whole subtree and fall back to local `org_members`.
_Avoid_: expired claim, demoted user

**Identity anchor**:
The directory key a Fleetworks principal is bound to: AD `object_guid`, with `distinguished_name` as fallback. Email is only a one-time linking hint.
_Avoid_: user id, email join

**Break-glass**:
Emergency authority outside normal role flow. In the RBAC plan it is a server-side table lookup, never a claim. In the hub scripts it is the **Hub provider key** path that works when the console is locked out.
_Avoid_: admin override, superuser

## Relationships

- The **Suite** has five **Apps**; the **Apex site** links to each and lists them from `@fleet-works/suite-nav`
- Each **App** has one **Accent color**; every page renders exactly one (**One Light Rule**)
- The **Hero Visual** draws all five **Apps** and lights the one whose page it is on
- Each **App** has one Supabase project, shared by its three **Client surfaces**
- Each **App**'s Supabase project is one **Relying party** in the **Hub** and registers one **Fleetworks provider**
- **Federation** makes an **App** **Dual-mode**; **Account linking** decides whether a hub sign-in joins an existing user or creates one
- The **Pilot** is **Sub-project** 1 and federated **Yellow Pages** first
- A **Product org** lives on the same **Hub** instance as the Suite's project and has exactly one **Org-scoped machine user**
- The **Hub provider key** creates **Product orgs**; an **Org-scoped machine user**'s key can act only inside its own org
- **Rolodex** is the RBAC control plane; `@cogs/auth` in each **App** is the enforcement plane; the **Hub** stays authentication-only
- The **Reconcile loop** turns **Bindings** into grants on each **Target**, under that **Target**'s **Enforcement level**, and writes the **Fleetworks claim**
- A **Fleetworks claim** holds only **AuthRoles**; a **Stale claim** is ignored
- A Fleetworks principal is bound to one directory row by its **Identity anchor**

## Flagged ambiguities

- "hub" is written as auth hub, identity hub, account hub and Fleetworks hub. Suggested: **Hub** is the Zitadel instance at `id.fleetworks.dev`; the login UI at `account.fleetworks.dev` is the **Account UI**. "Account hub" survives only as the name of sub-project 6 (a future profile/app-launcher UI).
- "fork" of Login v2: the pilot spec and plan say the **Account UI** is a fork of Zitadel's Login v2. `deploy/account/fly.toml` says it is the official image, "NOT a fork". Unresolved in the docs; the deploy config reflects what runs.
- "Render" vs "Fly": the pilot spec plans the **Hub** on Render. `deploy/zitadel/README.md` records the move to Fly after Render's edge broke native gRPC. `infra/hub-dns.tf` (a record `comment`) and `infra/dns.tf` (line 6) still say Render. The **Hub** runs on Fly.
- "five apps" vs "six apps": copy says five apps (`HeroVisual.tsx`, the home page), while PRODUCT.md and DESIGN.md say six, counting the **Apex site**. Use five for **Apps** and say "the apex plus five apps" when counting pages.
- "product" means a suite **App** in the hub plan docs ("product apps", "each product's Supabase project") but a non-suite product in **Product org**. Say **App** for suite members.
- "control plane" is used for Fleetworks as a whole (marketing copy), for Helmsman's agent governance, for **Rolodex** as the RBAC control plane, and for Zitadel's "configuration plane". Qualify it every time.
- "linking" means **Account linking** (hub identity to existing Supabase user, by verified email) in the hub docs. In the RBAC plan it also means binding a Fleetworks principal to a directory row via its **Identity anchor**. These are different joins; the RBAC plan stresses that authentication is not identification.
- "break-glass" has two meanings: the RBAC plan's server-side authority table, and the **Hub provider key** path in `scripts/zitadel-api.mjs`. Both are listed under **Break-glass**; name which one.
- "phase" is overloaded: auth Phase 1 and Phase 2, the RBAC plan's own Phase 0 to Phase 5, and "Phase 2 fan-out" of the separate portfolio secrets migration in `secrets.manifest.yml`. Name the plan with the phase.
- "sync" vs "reconcile": the RBAC plan uses `sync_run` for the directory import from AD and reconcile for writing grants and the **Fleetworks claim**. Do not use them interchangeably.
- "tenant" appears in Warden copy (a VCS provider/tenant), in "multi-tenant developers" (Yellow Pages copy), and in `@cogs/auth`'s "tenant vocabulary". It is not a Fleetworks domain term; use **Product org** or **App** for the concepts above.
