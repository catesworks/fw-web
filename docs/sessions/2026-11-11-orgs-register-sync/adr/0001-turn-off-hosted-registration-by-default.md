# 0001. Turn off hosted self-registration in the instance default login policy

Status: accepted (owner, 2026-11-11: merge now, hold the apply). Not yet applied.

## Context

The shared Zitadel instance's default login policy has `allow_register = true`. Anyone who reaches the hosted login can create an account in the default org. Such accounts hold no project role. Product apps that check a project role at sign-in refuse them, so the open registration only produces orphan accounts. A throwaway linkweave test account was created this way.

Product signup is meant to be owned by each app, which creates users through the Zitadel API. Product orgs inherit the instance default unless a product sets its own org login policy.

## Decision

Set `allow_register = false` on `zitadel_default_login_policy.fleetworks` (PR #14, merged as `1b10994`). Keep the apply separate, scoped with `-target=zitadel_default_login_policy.fleetworks`, and run it by the owner after uptimeloom's own org policy is applied.

## Options considered

- **Leave it on.** Rejected: no product uses hosted Register to onboard real users, and stray accounts accumulate in the default org.
- **Turn it off per product only.** Rejected as the only measure: a new org inherits the default until its own Terraform sets a policy, which is easy to forget.
- **Merge and apply together.** Rejected: uptimeloom's org policy was not yet applied, and the apply order only matters for its pre-launch registration test.

## Per-product dependency (as reported by each product session on 2026-11-08 to 2026-11-11)

| Product                              | Relies on the instance default? | Note                                                                                                |
| ------------------------------------ | ------------------------------- | --------------------------------------------------------------------------------------------------- |
| linkweave, bookweave, formweave      | No                              | Access is gated by a project role check. formweave creates users through the API with a registrar user. |
| hullstock                            | No                              | Its own org policy already sets registration off.                                                   |
| uptimeloom                           | No                              | Its own org policy sets registration on (merged, not applied).                                      |
| pipeo                                | No                              | Customers are invite-only; its own org policy sets registration off.                                |
| collectweave                         | Convenience only                | Owner chose to create designers by hand instead of an org policy.                                   |

## Consequences

- Hosted Register disappears for every org that does not set its own policy. Existing users, API-created users and sign-in are unaffected.
- The `main` branch says `false` while the live instance says `true` until the apply. A broader apply of the same root would flip it, which the plan doc already forbids.
- Product refusal tests that used a self-registered account to create a no-grant user need another way (an admin-created user without a grant).
- The API user-creation path rests on a source search, not a live test (see FOLLOWUPS).
