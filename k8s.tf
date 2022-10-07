resource "null_resource" "deploy_sh" {
  # change trigger to run every time
  depends_on = [module.eks.eks_managed_node_groups]
  triggers = {
    build_number = "${timestamp()}"
  }

  # download kubectl
  provisioner "local-exec" {
    command = "curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && chmod +x kubectl && mkdir -p ~/.local/bin && mv ./kubectl ~/.local/bin/kubectl"
  }

  provisioner "local-exec" {
    command = "aws eks --region ${var.region} update-kubeconfig --name ${var.cluster_name}"
  }

  provisioner "local-exec" {
    command = "chmod +x ./deploy.sh && ./deploy.sh"
  }
}

resource "kubernetes_storage_class" "ebs-sc" {
  metadata {
    name = "ebs-sc"
  }
  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Retain"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    encrypted = "true"
    kmsKeyId  = "${aws_kms_key.key-ebs-sc.arn}"
  }
}

resource "helm_release" "prometheus-elasticsearch-exporter" {
  name       = "prometheus-elasticsearch-exporter"
  namespace  = "elastic"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-elasticsearch-exporter"
  version    = "4.14.0"

  values = [
    "${file("./k8s/monitoring/elasticsearch-exporter-values.yml")}"
  ]

}

resource "helm_release" "kube-prometheus-stack" {
  name       = "prometheus"
  namespace  = "elastic"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "39.5.0"
  values = [
    "${file("./k8s/monitoring/prometheus-values.yml")}"
  ]

  set {
    name  = "config.route.routes.receiver[1]"
    value = var.cluster_name
  }
  set {
    name  = "config.route.receivers.name[1]"
    value = var.cluster_name
  }
}

resource "helm_release" "prometheus-msteams" {
  name       = "prometheus-msteams"
  namespace  = "elastic"
  repository = "https://prometheus-msteams.github.io/prometheus-msteams/"
  chart      = "prometheus-msteams"
  values = [
    "${file("./k8s/monitoring/msteams-values.yml")}"
  ]
}