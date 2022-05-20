provider "aws" {
    region = "eu-west-1"
  
}

resource "aws_s3_bucket" "terraform_state" {
    bucket="terraform-current-state-japcio"

    #Prevent accidental deletion of this S3 bucket
    lifecycle {
      prevent_destroy = true
    }
}

#Enable versioning
resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status ="Enabled"
  }
  
}

#Enable server-side encryption by default
resource "aws_s3_bucket_server_side_encryption_configuration" "defaut" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default{
      sse_algorithm = "AES256"
    }
  }
}


#Block public access to S3 bucket
resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.terraform_state.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}


#DynamoDB will be used for locking
resource "aws_dynamodb_table" "terraform_locks" {
  name  = "terraform-locks"
  billing_mode  = "PAY_PER_REQUEST"
  hash_key      = "LockID"
  
  attribute {
    name  = "LockID"
    type  = "S"
  }
}

terraform {
  backend "s3" {
    bucket  = "terraform-current-state-japcio"
    key     = "global/s3/terraform.tfstate"
    region  = "eu-west-1"

    dynamodb_table  = "terraform-locks"
    encrypt         = true
  }
}


output "s3_bucker_arn" {
  value = aws_s3_bucket.terraform_state.arn
  description = "The ARN of the s3 bucket"
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.terraform_locks.name
  description ="The name of the DynamoDB table"
}