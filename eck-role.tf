resource "aws_iam_role" "eck_role" {
  name               = "${var.cluster_name}-eck_role"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "AWS": "${data.aws_caller_identity.current.account_id}"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role_policy_attachment" "eck_role_policy_att" {
  role       = aws_iam_role.eck_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_kms_key" "key-ebs-sc" {
  description         = "KMS key for storageclass"
  enable_key_rotation = true
}
