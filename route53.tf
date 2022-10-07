resource "aws_route53_zone" "main" {
  vpc {
    vpc_id = data.aws_vpc.vpc.id
  }

  name = "${var.env}-${var.region}.ecoonline.net"
}

resource "aws_route53_record" "elastic" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "elastic.${aws_route53_zone.main.name}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${kubernetes_ingress_v1.eck_ingress.status.0.load_balancer.0.ingress.0.hostname}"]
}

resource "aws_route53_record" "kibana" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "kibana.${aws_route53_zone.main.name}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${kubernetes_ingress_v1.eck_ingress.status.0.load_balancer.0.ingress.0.hostname}"]
}

resource "aws_route53_record" "prometheus" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "prometheus.${aws_route53_zone.main.name}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${kubernetes_ingress_v1.eck_ingress.status.0.load_balancer.0.ingress.0.hostname}"]
}

resource "aws_route53_record" "alertmanager" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "alertmanager.${aws_route53_zone.main.name}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${kubernetes_ingress_v1.eck_ingress.status.0.load_balancer.0.ingress.0.hostname}"]
}



resource "aws_route53_resolver_endpoint" "main" {
  name      = "airswebdns"
  direction = "INBOUND"

  security_group_ids = [
    data.aws_security_group.sg.id
  ]

  ip_address {
    subnet_id = var.sub_private_1
  }

  ip_address {
    subnet_id = var.sub_private_2
  }
}