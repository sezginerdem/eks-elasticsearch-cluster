module "eks" {
  source                      = "terraform-aws-modules/eks/aws"
  version                     = "18.23.0"
  cluster_name                = var.cluster_name
  cluster_version             = var.cluster_v
  subnet_ids                  = ["${var.sub_private_1}", "${var.sub_private_2}"]
  vpc_id                      = var.vpc_id
  create_cloudwatch_log_group = false
  enable_irsa                 = true

  cluster_addons = {
    aws-ebs-csi-driver = {
      addon_version            = "v1.11.2-eksbuild.1"
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = module.irsa_role.iam_role_arn
    }
  }

  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  eks_managed_node_groups = {
    "${var.cluster_name}" = {
      iam_role_additional_policies = ["${aws_iam_policy.eco_eks_elastic_backup_bucket_policy.arn}"]
      instance_types               = ["${var.instance_type}"]
      create_launch_template       = false
      launch_template_name         = ""
      ebs_optimized                = true
      disk_size                    = var.ebs_size
      write_kubeconfig             = true
      config_output_path           = "./"

      desired_size = 3
      min_size     = 3
      max_size     = 6
      tags = {
        "Name"                                      = "${var.cluster_name}"
        "kubernetes.io/cluster/${var.cluster_name}" = "shared"
        "eks:cluster-name"                          = "${var.cluster_name}"
        "eks:nodegroup-name"                        = "elastic_eks"
      }
    }
  }

  # aws-auth configmap
  manage_aws_auth_configmap = true

  aws_auth_roles = [
    {
      rolearn  = aws_iam_role.eck_role.arn
      username = aws_iam_role.eck_role.name
      groups   = ["system:masters"]
    },
    {
      rolearn  = data.aws_iam_role.cloudops-role.arn
      username = data.aws_iam_role.cloudops-role.name
      groups   = ["system:masters"]
    },
    {
      rolearn  = data.aws_iam_role.architect-role.arn
      username = data.aws_iam_role.architect-role.name
      groups   = ["system:masters"]
    },
  ]
}


module "irsa_role" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name = "${var.region}-ebs-driver-cni-role"

  oidc_providers = {
    one = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
    two = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-node-sa"]
    }
  }

  role_policy_arns = {
    AmazonEKS_CNI_Policy = aws_iam_policy.AmazonEC2FullAccess-AmazonEBSCSIDriver.arn
    additional           = aws_iam_policy.eks_ebs-csi-policy.arn
  }
}


resource "aws_iam_policy" "eks_ebs-csi-policy" {
  name        = "${var.cluster_name}-eks_ebs-csi-policy"
  path        = "/"
  description = "eks_ebs-csi-policy"

  policy = jsonencode({
    "Version" : "2012-10-17"
    "Statement" : [
      {
        "Action" : [
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:RevokeGrant"
        ],
        "Condition" : {
          "Bool" : {
            "kms:GrantIsForAWSResource" : "true"
          }
        },
        "Effect" : "Allow",
        "Resource" : [
          "${aws_kms_key.key-ebs-sc.arn}"
        ]
      },
      {
        "Action" : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "${aws_kms_key.key-ebs-sc.arn}"
        ]
      }
    ],
    }
  )
}


resource "aws_iam_policy" "AmazonEC2FullAccess-AmazonEBSCSIDriver" {
  name        = "${var.cluster_name}-AmazonEC2FullAccess-AmazonEBSCSIDriver"
  path        = "/"
  description = "AmazonEC2FullAccess-AmazonEBSCSIDriver"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : "ec2:*",
          "Effect" : "Allow",
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : "elasticloadbalancing:*",
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : "cloudwatch:*",
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : "autoscaling:*",
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : "iam:CreateServiceLinkedRole",
          "Resource" : "*",
          "Condition" : {
            "StringEquals" : {
              "iam:AWSServiceName" : [
                "autoscaling.amazonaws.com",
                "ec2scheduled.amazonaws.com",
                "elasticloadbalancing.amazonaws.com",
                "spot.amazonaws.com",
                "spotfleet.amazonaws.com",
                "transitgateway.amazonaws.com"
              ]
            }
          }
        },
        {
          "Action" : [
            "kms:CreateGrant",
            "kms:ListGrants",
            "kms:RevokeGrant"
          ],
          "Condition" : {
            "Bool" : {
              "kms:GrantIsForAWSResource" : "true"
            }
          },
          "Effect" : "Allow",
          "Resource" : [
            "${aws_kms_key.key-ebs-sc.arn}"
          ]
        },
        {
          "Action" : [
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:DescribeKey"
          ],
          "Effect" : "Allow",
          "Resource" : [
            "${aws_kms_key.key-ebs-sc.arn}"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:CreateSnapshot",
            "ec2:AttachVolume",
            "ec2:DetachVolume",
            "ec2:ModifyVolume",
            "ec2:DescribeAvailabilityZones",
            "ec2:DescribeInstances",
            "ec2:DescribeSnapshots",
            "ec2:DescribeTags",
            "ec2:DescribeVolumes",
            "ec2:DescribeVolumesModifications"
          ],
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:CreateTags"
          ],
          "Resource" : [
            "arn:aws:ec2:*:*:volume/*",
            "arn:aws:ec2:*:*:snapshot/*"
          ],
          "Condition" : {
            "StringEquals" : {
              "ec2:CreateAction" : [
                "CreateVolume",
                "CreateSnapshot"
              ]
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:DeleteTags"
          ],
          "Resource" : [
            "arn:aws:ec2:*:*:volume/*",
            "arn:aws:ec2:*:*:snapshot/*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:CreateVolume"
          ],
          "Resource" : "*",
          "Condition" : {
            "StringLike" : {
              "aws:RequestTag/ebs.csi.aws.com/cluster" : "true"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:CreateVolume"
          ],
          "Resource" : "*",
          "Condition" : {
            "StringLike" : {
              "aws:RequestTag/CSIVolumeName" : "*"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:CreateVolume"
          ],
          "Resource" : "*",
          "Condition" : {
            "StringLike" : {
              "aws:RequestTag/kubernetes.io/cluster/*" : "owned"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:DeleteVolume"
          ],
          "Resource" : "*",
          "Condition" : {
            "StringLike" : {
              "ec2:ResourceTag/ebs.csi.aws.com/cluster" : "true"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:DeleteVolume"
          ],
          "Resource" : "*",
          "Condition" : {
            "StringLike" : {
              "ec2:ResourceTag/CSIVolumeName" : "*"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:DeleteVolume"
          ],
          "Resource" : "*",
          "Condition" : {
            "StringLike" : {
              "ec2:ResourceTag/kubernetes.io/cluster/*" : "owned"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:DeleteSnapshot"
          ],
          "Resource" : "*",
          "Condition" : {
            "StringLike" : {
              "ec2:ResourceTag/CSIVolumeSnapshotName" : "*"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:DeleteSnapshot"
          ],
          "Resource" : "*",
          "Condition" : {
            "StringLike" : {
              "ec2:ResourceTag/ebs.csi.aws.com/cluster" : "true"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:CreateSnapshot",
            "ec2:AttachVolume",
            "ec2:DetachVolume",
            "ec2:ModifyVolume",
            "ec2:DescribeAvailabilityZones",
            "ec2:DescribeInstances",
            "ec2:DescribeSnapshots",
            "ec2:DescribeTags",
            "ec2:DescribeVolumes",
            "ec2:DescribeVolumesModifications"
          ],
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:CreateTags"
          ],
          "Resource" : [
            "arn:aws:ec2:*:*:volume/*",
            "arn:aws:ec2:*:*:snapshot/*"
          ],
          "Condition" : {
            "StringEquals" : {
              "ec2:CreateAction" : [
                "CreateVolume",
                "CreateSnapshot"
              ]
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:DeleteTags"
          ],
          "Resource" : [
            "arn:aws:ec2:*:*:volume/*",
            "arn:aws:ec2:*:*:snapshot/*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:CreateVolume"
          ],
          "Resource" : "*",
          "Condition" : {
            "StringLike" : {
              "aws:RequestTag/ebs.csi.aws.com/cluster" : "true"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:CreateVolume"
          ],
          "Resource" : "*",
          "Condition" : {
            "StringLike" : {
              "aws:RequestTag/CSIVolumeName" : "*"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:CreateVolume"
          ],
          "Resource" : "*",
          "Condition" : {
            "StringLike" : {
              "aws:RequestTag/kubernetes.io/cluster/*" : "owned"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:DeleteVolume"
          ],
          "Resource" : "*",
          "Condition" : {
            "StringLike" : {
              "ec2:ResourceTag/ebs.csi.aws.com/cluster" : "true"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:DeleteVolume"
          ],
          "Resource" : "*",
          "Condition" : {
            "StringLike" : {
              "ec2:ResourceTag/CSIVolumeName" : "*"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:DeleteVolume"
          ],
          "Resource" : "*",
          "Condition" : {
            "StringLike" : {
              "ec2:ResourceTag/kubernetes.io/cluster/*" : "owned"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:DeleteSnapshot"
          ],
          "Resource" : "*",
          "Condition" : {
            "StringLike" : {
              "ec2:ResourceTag/CSIVolumeSnapshotName" : "*"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:DeleteSnapshot"
          ],
          "Resource" : "*",
          "Condition" : {
            "StringLike" : {
              "ec2:ResourceTag/ebs.csi.aws.com/cluster" : "true"
            }
          }
        }
      ]
    }
  )
}

resource "aws_ec2_tag" "vpc_tag" {
  resource_id = var.vpc_id
  key         = "kubernetes.io/cluster/${var.cluster_name}"
  value       = "shared"
}

data "aws_vpc" "vpc" {
  id = var.vpc_id
}


resource "aws_ec2_tag" "private_sub_tag" {
  for_each    = toset(["${var.sub_private_1}", "${var.sub_private_2}"])
  resource_id = each.value
  key         = "kubernetes.io/role/internal-elb"
  value       = "1"
}

resource "aws_ec2_tag" "private_sub_cluster_tag" {
  for_each    = toset(["${var.sub_private_1}", "${var.sub_private_2}"])
  resource_id = each.value
  key         = "kubernetes.io/cluster/${var.cluster_name}"
  value       = "shared"
}

resource "aws_ec2_tag" "public_sub_tag" {
  for_each    = toset(["${var.sub_public_1}", "${var.sub_public_2}"])
  resource_id = each.value
  key         = "kubernetes.io/role/elb"
  value       = "1"
}

resource "aws_ec2_tag" "public_sub_cluster_tag" {
  for_each    = toset(["${var.sub_public_1}", "${var.sub_public_2}"])
  resource_id = each.value
  key         = "kubernetes.io/cluster/${var.cluster_name}"
  value       = "shared"
}

resource "aws_iam_policy" "eco_eks_elastic_backup_bucket_policy" {
  name        = "${var.cluster_name}_eco_eks_elastic_backup_bucket_policy"
  description = "eco_eks_elastic_backup_bucket policy"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "VisualEditor0",
          "Effect" : "Allow",
          "Action" : [
            "s3:PutObject",
            "s3:GetObject",
            "s3:ListBucketMultipartUploads",
            "s3:AbortMultipartUpload",
            "s3:ListBucket",
            "s3:DeleteObject",
            "s3:ListMultipartUploadParts"
          ],
          "Resource" : [
            "${module.s3_bucket.s3_bucket_arn}/*",
            "${module.s3_bucket.s3_bucket_arn}"
          ]
        }
      ]
  })
}

