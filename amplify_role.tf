provider "aws" {
  region = "us-east-1" # Cambia la región si usás otra
}

# Política personalizada para frontend, CI/CD y Amplify Console
resource "aws_iam_policy" "amplify_frontend_policy" {
  name        = "AmplifyDeployFrontendAccess"
  description = "Permite el uso de Amplify Console y servicios CI/CD"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AmplifyConsoleAccess",
        Effect = "Allow",
        Action = [
          "amplify:CreateApp",
          "amplify:UpdateApp",
          "amplify:CreateBranch",
          "amplify:StartDeployment",
          "amplify:GetApp",
          "amplify:GetBranch",
          "amplify:ListApps",
          "amplify:ListBranches",
          "amplify:ListJobs"
        ],
        Resource = "*"
      },
      {
        Sid    = "CIandLogs",
        Effect = "Allow",
        Action = [
          "codebuild:*",
          "logs:*",
          "cloudwatch:*"
        ],
        Resource = "*"
      }
    ]
  })
}

# Rol IAM para Amplify
resource "aws_iam_role" "amplify_full_role" {
  name = "AmplifyFullRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "amplify.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Asociar política administrada de AWS Amplify backend
resource "aws_iam_role_policy_attachment" "attach_backend_full_access" {
  role       = aws_iam_role.amplify_full_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmplifyBackendDeployFullAccess"
}

# Asociar política personalizada (frontend + CI/CD)
resource "aws_iam_role_policy_attachment" "attach_custom_policy" {
  role       = aws_iam_role.amplify_full_role.name
  policy_arn = aws_iam_policy.amplify_frontend_policy.arn
}
