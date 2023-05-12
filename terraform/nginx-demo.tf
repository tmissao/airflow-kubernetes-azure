resource "kubernetes_deployment_v1" "nginx" {
  count = var.deploy_nginx_demo.deploy ? 1 : 0
  metadata {
    name   = "${var.deploy_nginx_demo.name}-dpl"
    labels = var.deploy_nginx_demo.labels
  }
  spec {
    replicas = 1
    selector {
      match_labels = var.deploy_nginx_demo.labels
    }
    template {
      metadata {
        labels = var.deploy_nginx_demo.labels
      }
      spec {
        container {
          image = var.deploy_nginx_demo.image
          name  = "${var.deploy_nginx_demo.name}-ctn"
          port {
            container_port = var.deploy_nginx_demo.port
          }
          liveness_probe {
            http_get {
              path = "/"
              port = var.deploy_nginx_demo.port
            }
            initial_delay_seconds = 3
            period_seconds        = 3
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "nginx" {
  count = var.deploy_nginx_demo.deploy ? 1 : 0
  metadata {
    name = "${var.deploy_nginx_demo.name}-svc"
  }
  spec {
    selector = var.deploy_nginx_demo.labels
    port {
      port        = var.deploy_nginx_demo.port
      target_port = var.deploy_nginx_demo.port
    }
  }
}

resource "kubernetes_ingress_v1" "nginx" {
  count = var.deploy_nginx_demo.deploy ? 1 : 0
  metadata {
    name = "${var.deploy_nginx_demo.name}-ign"
    annotations = {
      "nginx.ingress.kubernetes.io/ssl-redirect" : "false"
      "nginx.ingress.kubernetes.io/rewrite-target" = "/$2"
    }
  }
  spec {
    ingress_class_name = "nginx"
    rule {
      http {
        path {
          backend {
            service {
              name = one(kubernetes_service_v1.nginx).metadata[0].name
              port {
                number = var.deploy_nginx_demo.port
              }
            }
          }
          path      = "${var.deploy_nginx_demo.path}(/|$)(.*)"
          path_type = "Prefix"
        }
      }
    }
  }
}