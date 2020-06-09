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

resource "k8s_manifest" "namespace_2048-game" {
  content = <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: "2048-game"
EOF
  depends_on = [var.depends]
}

resource "k8s_manifest" "deployment_2048-game" {
  content = <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: "2048-deployment"
  namespace: "2048-game"
spec:
  selector:
    matchLabels:
      app: "2048"
  replicas: 5
  template:
    metadata:
      labels:
        app: "2048"
    spec:
      containers:
      - image: ${aws_ecr_repository.repo_2048-game.repository_url}:latest
        imagePullPolicy: Always
        name: "2048"
        ports:
        - containerPort: 80
EOF
  depends_on = [var.depends]
}

resource "k8s_manifest" "service_2048-game" {
  content = <<EOF
apiVersion: v1
kind: Service
metadata:
  name: "service-2048"
  namespace: "2048-game"
spec:
  ports:
    - port: 80
      targetPort: 80
      protocol: TCP
  type: NodePort
  selector:
    app: "2048"
EOF
  depends_on = [var.depends]
}

resource "k8s_manifest" "ingress_2048-game" {
  content = <<EOF
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: "2048-ingress"
  namespace: "2048-game"
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internal
    alb.ingress.kubernetes.io/target-type: ip
    external-dns.alpha.kubernetes.io/hostname: 2048-game.example.com
  labels:
    app: 2048-ingress
spec:
  rules:
    - http:
        paths:
          - path: /*
            backend:
              serviceName: "service-2048"
              servicePort: 80
EOF
  depends_on = [k8s_manifest.service_2048-game]
}
