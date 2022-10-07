output "region" {
  description = "AWS Region"
  value       = var.region
}

output "cluster_name" {
  description = "EKS Cluster Name"
  value       = var.cluster_name
}

output "load_balancer_hostname" {
  depends_on = [time_sleep.wait_60_seconds]
  value      = kubernetes_ingress_v1.eck_ingress.status.0.load_balancer.0.ingress.0.hostname
}

output "kibana_url" {
  value = "https://kibana.${var.env}-${var.region}.ecoonline.net"
}

output "elastic_url" {
  value = "https://elastic.${var.env}-${var.region}.ecoonline.net"
}


output "prometheus_url" {
  value = "https://prometheus.${var.env}-${var.region}.ecoonline.net"
}

output "alertmanager_url" {
  value = "https://alertmanager.${var.env}-${var.region}.ecoonline.net"
}


output "admin_kube_configfile_update" {
  value = "aws eks update-kubeconfig --name ${var.cluster_name} --region ${var.region} --role-arn ${aws_iam_role.eck_role.arn}"
}

output "cloudops-role_kube_configfile_update" {
  value = "aws eks update-kubeconfig --name ${var.cluster_name} --region ${var.region} --role-arn ${data.aws_iam_role.architect-role.arn}"
}

output "architect-role_kube_configfile_update" {
  value = "aws eks update-kubeconfig --name ${var.cluster_name} --region ${var.region} --role-arn ${data.aws_iam_role.cloudops-role.arn}"
}
