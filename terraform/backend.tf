terraform {
  backend "s3" {
    bucket         = "YOUR-TFSTATE-BUCKET"       # TODO: change to your state bucket
    key            = "logging/terraform.tfstate" # TODO: change the state path if needed
    region         = "us-east-1"                 # TODO: change to the bucket region
    dynamodb_table = "YOUR-TFSTATE-LOCK-TABLE"   # TODO: change to your lock table name
    encrypt        = true
  }
}
