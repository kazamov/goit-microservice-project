#terraform {
#  backend "s3" {
#    bucket         = "terraform-state-bucket-127214174194" # Назва S3-бакета
#    key            = "lesson-5/terraform.tfstate"          # Шлях до файлу стейту
#    region         = "eu-central-1"                        # Регіон AWS
#    dynamodb_table = "terraform-locks"                     # Назва таблиці DynamoDB
#    use_lockfile   = true
#    encrypt        = true # Шифрування файлу стейту
#  }
#}
