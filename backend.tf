#terraform {
#  backend "s3" {
#    bucket         = "terraform-state-bucket-127214174194" # S3 bucket name
#    key            = "lesson-5/terraform.tfstate"          # Path to state file
#    region         = "eu-central-1"                        # AWS region
#    dynamodb_table = "terraform-locks"                     # DynamoDB table name
#    use_lockfile   = true
#    encrypt        = true # State file encryption
#  }
#}
