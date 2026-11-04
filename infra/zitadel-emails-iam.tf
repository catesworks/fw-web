# IAM user for the zitadel-emails worker (catesworks/zitadel-emails).
#
# The worker renders each Zitadel notification and sends it with SESv2 SendEmail,
# choosing the From address per product (model B). One user, one inline policy,
# scoped by the `ses:FromAddress` condition (never `ses:FromDomain`, never a bare
# `*`). Scoping the statement to identity ARNs blocks sending with a 554 for the
# same reason documented in iam.tf, so `Resource = "*"` plus the condition is the
# working shape.
#
# ONLY the user and the policy are Terraformed. The access key is created
# out-of-band so its secret never enters Terraform state:
#
#   aws iam create-access-key --user-name zitadel-emails-worker --output json
#
# The response contains the secret: capture it into variables or a 0600 template for
# 1Password and never let it reach a terminal, a log or a file that is kept.
#
# Adding a product = add its From pattern here, add its org to
# config/senders.json in zitadel-emails, and set SES_ALLOWED_FROM_PATTERNS to the
# same list (the worker refuses to start if a configured sender matches none).
locals {
  zitadel_emails_from_patterns = [
    "no-reply@auth.id.fleetworks.dev", # neutral default sender for unmapped orgs
  ]
}

resource "aws_iam_user" "zitadel_emails_worker" {
  name = "zitadel-emails-worker"
  path = "/cogs/ses/"

  tags = {
    Project = "zitadel-emails"
    Purpose = "ses-send-per-product-from"
  }
}

resource "aws_iam_user_policy" "zitadel_emails_worker_send" {
  name = "ses-send-zitadel-emails"
  user = aws_iam_user.zitadel_emails_worker.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowSendEmailAsListedFromAddresses"
        Effect    = "Allow"
        Action    = ["ses:SendEmail"]
        Resource  = "*"
        Condition = { StringLike = { "ses:FromAddress" = local.zitadel_emails_from_patterns } }
      }
    ]
  })
}
