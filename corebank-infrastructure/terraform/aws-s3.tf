resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "kyc_vault" {
  bucket        = "corebank-kyc-vault-${random_id.bucket_suffix.hex}"
  force_destroy = true # Allows easy cleanup later when tearing down your staging infrastructure
}

resource "aws_s3_bucket_server_side_encryption_configuration" "kyc_encryption" {
  bucket = aws_s3_bucket.kyc_vault.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket = aws_s3_bucket.kyc_vault.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
