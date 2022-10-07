resource "kubernetes_namespace" "namespace" {
  metadata {
    name = "elastic"
  }
}

resource "kubernetes_horizontal_pod_autoscaler" "hpa" {
  metadata {
    name      = "hpa"
    namespace = "elastic"
  }

  spec {
    max_replicas                      = 6
    min_replicas                      = 3
    target_cpu_utilization_percentage = 70

    scale_target_ref {
      api_version = "apps/v1"
      kind        = "StatefulSet"
      name        = "elastic-es-data"
    }
  }
}

module "eks-cluster-autoscaler" {
  source  = "lablabs/eks-cluster-autoscaler/aws"
  version = "2.0.0"

  enabled           = true
  argo_enabled      = false
  argo_helm_enabled = false

  cluster_name                     = module.eks.cluster_id
  cluster_identity_oidc_issuer     = module.eks.cluster_oidc_issuer_url
  cluster_identity_oidc_issuer_arn = module.eks.oidc_provider_arn

  irsa_role_name_prefix = var.cluster_name

  values = yamlencode({
    "image" : {
      "tag" : "v1.22.3"
    }
  })
}