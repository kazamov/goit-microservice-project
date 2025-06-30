output "repository_url" {
  description = "The URL of the repository"
  value       = aws_ecr_repository.ecr_main.repository_url
}

output "repository_arn" {
  description = "The ARN of the repository"
  value       = aws_ecr_repository.ecr_main.arn
}

output "repository_name" {
  description = "The name of the repository"
  value       = aws_ecr_repository.ecr_main.name
}

output "registry_id" {
  description = "The registry ID where the repository was created"
  value       = aws_ecr_repository.ecr_main.registry_id
}
