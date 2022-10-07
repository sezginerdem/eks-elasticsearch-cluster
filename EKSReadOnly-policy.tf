resource "aws_iam_policy" "eks-read-only" {
  name        = "${var.cluster_name}-EKSReadOnly"
  path        = "/"
  description = "Read-Only policy for all EKS resources"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "Rule0",
          "Effect" : "Allow",
          "Action" : [
            "eks:ListNodegroups",
            "eks:DescribeFargateProfile",
            "eks:ListTagsForResource",
            "eks:ListAddons",
            "eks:DescribeAddon",
            "eks:ListFargateProfiles",
            "eks:DescribeNodegroup",
            "eks:DescribeIdentityProviderConfig",
            "eks:ListUpdates",
            "eks:DescribeUpdate",
            "eks:AccessKubernetesApi",
            "eks:DescribeCluster",
            "eks:ListClusters",
            "eks:DescribeAddonVersions",
            "eks:ListIdentityProviderConfigs"
          ],
          "Resource" : "*"
        },
        {
          "Sid" : "Rule1",
          "Effect" : "Allow",
          "Action" : "iam:PassRole",
          "Resource" : "*",
          "Condition" : {
            "StringEquals" : {
              "iam:PassedToService" : "eks.amazonaws.com"
            }
          }
        }
      ]
    }

  )

}
