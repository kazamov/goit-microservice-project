resource "aws_ecr_repository" "ecr_main" {
  name                 = var.ecr_name
  image_tag_mutability = var.image_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = var.encryption_configuration.encryption_type
    kms_key         = var.encryption_configuration.kms_key
  }

  tags = merge(
    {
      Name        = var.ecr_name
      Environment = "lesson-5"
    },
    var.tags
  )
}

# ECR Repository Policy (if provided)
resource "aws_ecr_repository_policy" "ecr_policy" {
  count      = var.repository_policy != "" ? 1 : 0
  repository = aws_ecr_repository.ecr_main.name
  policy     = var.repository_policy
}

# ECR Lifecycle Policy (if provided)
resource "aws_ecr_lifecycle_policy" "ecr_lifecycle" {
  count      = var.lifecycle_policy != "" ? 1 : 0
  repository = aws_ecr_repository.ecr_main.name
  policy     = var.lifecycle_policy
}

# Default lifecycle policy to keep only the latest 10 images
resource "aws_ecr_lifecycle_policy" "default_lifecycle" {
  count      = var.lifecycle_policy == "" ? 1 : 0
  repository = aws_ecr_repository.ecr_main.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only the latest 10 images"
        selection = {
          tagStatus   = "untagged"
          countType   = "imageCountMoreThan"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep only the latest 10 tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "latest", "prod", "dev", "staging"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
