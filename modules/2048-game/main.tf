resource "aws_ecr_repository" "repo_2048-game" {
  name = "2048-game"
}

# Pulls 2048 docker image and pushes it into aws_ecr_repository
resource "null_resource" "ecr_image" {
  # Runs the build.sh script
  provisioner "local-exec" {
    command = "bash ${path.module}/bin/build.sh alexwhen/docker-2048:latest ${aws_ecr_repository.repo_2048-game.repository_url}:latest"
  }
}

resource "kubernetes_namespace" "namespace_2048-game" {
  metadata {
    name = "2048-game"
  }
  depends_on = [var.depends]
}

resource "kubernetes_deployment" "deployment_2048-game" {
  metadata {
    name      = "2048-deployment"
    namespace = "2048-game"
  }

  spec {
    replicas = 4

    selector {
      match_labels = {
        app = "2048"
      }
    }

    template {
      metadata {
        labels = {
          app = "2048"
        }
      }

      spec {
        container {
          image = "${aws_ecr_repository.repo_2048-game.repository_url}:latest"
          name  = "2048"

          resources {
            limits {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests {
              cpu    = "250m"
              memory = "50Mi"
            }
          }

          port {
            container_port = 80
          }
        }
      }
    }
  }
  depends_on = [var.depends]
}

resource "kubernetes_service" "service_2048-game" {
  metadata {
    name      = "service-2048"
    namespace = "2048-game"
  }
  spec {
    selector = {
      app = "2048"
    }
    port {
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }
    type = "NodePort"
  }
  depends_on = [var.depends]
}

resource "kubernetes_ingress" "ingress_2048-game" {
  metadata {
    name      = "2048-ingress"
    namespace = "2048-game"
    annotations = {
      "kubernetes.io/ingress.class"               = "alb"
      "alb.ingress.kubernetes.io/scheme"          = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"     = "ip"
      "external-dns.alpha.kubernetes.io/hostname" = "2048-game.example.com"
    }
    labels = {
      app = "2048-ingress"
    }
  }

  spec {
    rule {
      http {
        path {
          backend {
            service_name = "service-2048"
            service_port = 80
          }

          path = "/*"
        }
      }
    }
  }
  depends_on = [kubernetes_service.service_2048-game]
}
