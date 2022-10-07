resource "time_sleep" "wait_90_seconds" {
  depends_on      = [helm_release.lb]
  create_duration = "90s"
}

resource "kubernetes_ingress_v1" "eck_ingress" {
  depends_on = [time_sleep.wait_90_seconds]
  metadata {
    name      = "${var.cluster_name}-ingress"
    namespace = "elastic"
    annotations = {
      "alb.ingress.kubernetes.io/load-balancer-name" = "eck-lb"
      "kubernetes.io/aws-load-balancer-type"         = "internal"
      "kubernetes.io/ingress.class"                  = "alb"
      "alb.ingress.kubernetes.io/inbound-cidrs"      = "0.0.0.0/0, ::/0"
      "alb.ingress.kubernetes.io/scheme"             = "internal"
      # "alb.ingress.kubernetes.io/healthcheck-interval-seconds" = "15"
      # "alb.ingress.kubernetes.io/healthcheck-path"             = "/"
      # "alb.ingress.kubernetes.io/healthcheck-port"             = "traffic-port"
      # "alb.ingress.kubernetes.io/healthcheck-protocol"         = "HTTP"
      # "alb.ingress.kubernetes.io/healthcheck-timeout-seconds"  = "5"
      # "alb.ingress.kubernetes.io/healthy-threshold-count"      = "2"
      # "alb.ingress.kubernetes.io/rewrite-target"               = "/$2"
      # "alb.ingress.kubernetes.io/success-codes"                = "200"
      # "alb.ingress.kubernetes.io/unhealthy-threshold-count" : "2"
      "alb.ingress.kubernetes.io/manage-backend-security-group-rules" = "true"
      "alb.ingress.kubernetes.io/listen-ports"                        = <<JSON
[{"HTTPS": 443}]
JSON
      "alb.ingress.kubernetes.io/certificate-arn"                     = "${var.alb_ssl_certificate}"
    }
  }
  spec {
    rule {
      host = "kibana.${var.env}-${var.region}.ecoonline.net"
      http {
        path {
          backend {
            service {
              name = "kibana-kb-http"
              port {
                number = 5601
              }
            }
          }
          path = "/*"
        }
      }
    }
    rule {
      host = "elastic.${var.env}-${var.region}.ecoonline.net"
      http {
        path {
          backend {
            service {
              name = "elastic-es-http"
              port {
                number = 9200
              }
            }
          }
          path = "/*"
        }
      }
    }
    rule {
      host = "prometheus.${var.env}-${var.region}.ecoonline.net"
      http {
        path {
          backend {
            service {
              name = "prometheus-kube-prometheus-prometheus"
              port {
                number = 9090
              }
            }
          }
          path = "/*"
        }
      }
    }
    rule {
      host = "alertmanager.${var.env}-${var.region}.ecoonline.net"
      http {
        path {
          backend {
            service {
              name = "prometheus-kube-prometheus-alertmanager"
              port {
                number = 9093
              }
            }
          }
          path = "/*"
        }
      }
    }
  }
  wait_for_load_balancer = true
}

resource "time_sleep" "wait_60_seconds" {
  depends_on      = [kubernetes_ingress_v1.eck_ingress]
  create_duration = "60s"
}
