#
# provider config
#
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.20.0"
    }
  }
}

#
# variables
#
variable "oidc_provider" {
  description = "The OIDC provider"
  type        = string
}

variable "demo_secret" {
  description = "Demo SecretsManager secret to create."
  type = object({
    name                      = string
    service_account_name      = string
    service_account_namespace = string
    policy_name               = string
    role_name                 = string
  })
  default = {
    name                      = "Demo"
    service_account_name      = "external-secrets"
    service_account_namespace = "vms"
    policy_name               = "dscott-external-secrets"
    role_name                 = "dscott-external-secrets"
  }
}

variable "demo_cloudwatch" {
  description = "Demo CloudWatch variable."
  type = object({
    service_account_name      = string
    service_account_namespace = string
    policy_name               = string
    role_name                 = string
  })
  default = {
    service_account_name      = "cloudwatch"
    service_account_namespace = "openshift-logging"
    policy_name               = "dscott-cloudwatch"
    role_name                 = "dscott-cloudwatch"
  }
}

#
# lookups
#
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_iam_openid_connect_provider" "oidc_provider" {
  url = "https://${var.oidc_provider}"
}

#
# iam roles and policies
#

# secrets manager
resource "aws_iam_policy" "secrets_manager" {
  name        = var.demo_secret.policy_name
  description = "Policy allowing access to specific secrets in AWS Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.demo_secret.name}*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "secrets_manager" {
  name = var.demo_secret.role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Condition = {
          StringEquals = {
            "${var.oidc_provider}:sub" = [
              "system:serviceaccount:${var.demo_secret.service_account_namespace}:${var.demo_secret.service_account_name}"
            ]
          }
        }
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.oidc_provider.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "secrets_manager" {
  role       = aws_iam_role.secrets_manager.name
  policy_arn = aws_iam_policy.secrets_manager.arn
}

# cloudwatch
resource "aws_iam_policy" "cloudwatch" {
  name        = var.demo_cloudwatch.policy_name
  description = "Policy allowing access to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
          "logs:PutRetentionPolicy"
        ]
        Resource = [
          "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "cloudwatch" {
  name = var.demo_cloudwatch.role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Condition = {
          StringEquals = {
            "${var.oidc_provider}:sub" = [
              "system:serviceaccount:${var.demo_cloudwatch.service_account_namespace}:${var.demo_cloudwatch.service_account_name}"
            ]
          }
        }
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.oidc_provider.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.cloudwatch.name
  policy_arn = aws_iam_policy.cloudwatch.arn
}

#
# secrets manager secret
#
resource "aws_secretsmanager_secret" "demo" {
  name        = var.demo_secret.name
  description = "Demo secret storing username and password"
}

resource "aws_secretsmanager_secret_version" "demo" {
  secret_id = aws_secretsmanager_secret.demo.id

  # NOTE: this is for demo purposes only and is not used in the real world
  secret_string = jsonencode({
    username = "username"
    password = "password"
  })
}
