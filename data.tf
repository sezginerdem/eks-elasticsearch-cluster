# Security Group Data
data "aws_security_group" "sg" {
  tags = {
    Name = var.security_group
  }
}

data "aws_iam_role" "cloudops-role" {
  name = "CloudOps"
}

data "aws_iam_role" "architect-role" {
  name = "Architect"
}
