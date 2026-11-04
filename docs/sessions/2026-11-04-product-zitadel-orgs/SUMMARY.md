# Summary

## What was done

- Phase A: asked seven product sessions (bookweave, formweave, linkweave, pipeo, uptimeloom, hullstock, collectweave) for org name, existing drafts, users in the org, and in-org Terraform credential. None had drafted or applied an org creation on the prod instance. The owner chose scope, machine users and key handling.
- PR #6 (`811bc14`): `infra/zitadel-product-orgs.tf` creates eight orgs (bookweave, collectweave, formweave, hullstock, linkweave, pipeo, pipeo-staff, uptimeloom) with `prevent_destroy`, plus one `<org>-terraform` machine user and an `ORG_OWNER` membership per org. No key or PAT resource. Plan doc: `docs/plans/zitadel-product-orgs.md`. An independent reviewer approved after one round of fixes.
- PR #7 (`3811fcb`): documented the minting credential (hub IAM_OWNER provider key, read only by the script), the API call, base64 decoding, and cleanup.
- Owner applied the three-target apply: 24 added, 0 changed, 0 destroyed.
- Minted one JWT-profile key per machine user (expiry 2027-12-04) straight into 1Password `infra-access`, items `fw-web/zitadel-<org>-terraform/prod`. Recorded all org and user ids (non-secret) in item `fw-web/zitadel-product-orgs/prod`.
- Calendar reminders created for 2027-11-04 (rotate) and 2027-12-04 (expiry).
- Sent each product session its org id, machine user id and key location; sent zitadel-emails-worker all eight ids and asked it to own the sender-mapping batch.

## Org ids (not secrets)

bookweave 398176037764071782, collectweave 398176037747294566, formweave 398176037847957862, hullstock 398176037696962918, linkweave 398176037898289510, pipeo 398176038015730022, pipeo-staff 398176037730517350, uptimeloom 398176037831180646.
