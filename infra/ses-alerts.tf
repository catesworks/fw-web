# Dedicated SES SMTP credential for operational alert mail (Uptime Kuma on the app-02
# CapRover box, 2026-10-05). Separate from the hub's Zitadel credential (iam.tf) so it can
# be rotated or revoked on its own, and sends ONLY as the hub identity domain, so a
# leaked alert credential cannot send as any product brand. Same policy shape as
# iam.tf's ses_send (FromAddress condition, NOT resource scope: see that comment).
#
# Read the values with `terraform output -raw uptime_kuma_smtp_username` /
# `uptime_kuma_smtp_password` and store them in 1Password (infra-access item
# `uptime-kuma/ses-smtp`); never commit them. The SMTP password is the SigV4
# derivation of the secret key (provider attribute ses_smtp_password_v4).
resource "aws_iam_user" "alerts" {
  name = "ses-smtp-alerts"
  path = "/cogs/ses/"

  tags = {
    Project     = "fleetworks-hub"
    Purpose     = "uptime-kuma-alerts"
    SESIdentity = var.hub_identity_domain
  }

  lifecycle {
    precondition {
      condition     = contains(keys(var.domains), var.hub_identity_domain)
      error_message = "hub_identity_domain must be a key of var.domains so its SES identity exists."
    }
  }
}

resource "aws_iam_access_key" "alerts" {
  user = aws_iam_user.alerts.name
}

resource "aws_iam_user_policy" "alerts_send" {
  name = "ses-send-alerts"
  user = aws_iam_user.alerts.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowSendRawEmailAsHubOnly"
        Effect    = "Allow"
        Action    = ["ses:SendRawEmail"]
        Resource  = "*"
        Condition = { StringLike = { "ses:FromAddress" = "*@${var.hub_identity_domain}" } }
      }
    ]
  })
}

output "uptime_kuma_smtp_host" {
  description = "SES SMTP endpoint for Uptime Kuma alerts (STARTTLS on 587)."
  value       = "email-smtp.${var.ses_region}.amazonaws.com"
}

output "uptime_kuma_smtp_username" {
  description = "SES SMTP username (IAM access key id) for Uptime Kuma alerts."
  value       = aws_iam_access_key.alerts.id
  sensitive   = true
}

output "uptime_kuma_smtp_password" {
  description = "SES SMTP password (SigV4-derived) for Uptime Kuma alerts."
  value       = aws_iam_access_key.alerts.ses_smtp_password_v4
  sensitive   = true
}
