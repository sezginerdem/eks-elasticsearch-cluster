module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket             = "${var.cluster_name}-eco-backup-elastic"
  acl                = "private"
  ignore_public_acls = true

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
}

