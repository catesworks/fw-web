# Follow-ups

## Blocked on the owner

1. Approve and run the targeted IAM policy apply (`aws_iam_user_policy.zitadel_emails_worker_send`, expect 1 to change) when zitadel-emails-worker brings the combined From-pattern PR.
2. Approve the 1Password prompts for the worker's `SES_ALLOWED_FROM_PATTERNS` update and the bundled zitadel-emails release.
3. Each product applies its own SES identity (formweave's `auth.formweave.catesworks.dev` is owner-gated and not applied) and its own in-org Terraform with its `<org>-terraform` key.
4. Rotate the eight keys before 2027-12-04 (calendar reminder on 2027-11-04). Replace them with a fresh mint into the same 1Password items.

## Blocked on remaining work

1. fw-web PRs #8 to #12 (one From address each) are superseded by one combined PR that zitadel-emails-worker will open once identities are verified. Do not merge them one by one.
2. Verify whether `ORG_OWNER` can delete its own org in this Zitadel version (reviewer's open question).
3. collectweave still plans a project grant into the fleet org, which its `ORG_OWNER`-on-own-org key cannot create. It needs a broader credential or the redesign bookweave and linkweave chose (owner user inside the product org).
4. pipeo-staff maps to the same sender as pipeo (owner decision); pipeo adds two `senders.json` entries and one From pattern.
5. Optional: switch the minting script to the v2 API (`POST /v2/users/{userId}/keys`); v1 is deprecated but works.
