# EKS Fargate Working Example

Install [third party k8s terraform plugin](https://github.com/banzaicloud/terraform-provider-k8s):
```
mkdir -p ~/.terraform.d/plugins
wget -qO- https://github.com/banzaicloud/terraform-provider-k8s/releases/download/v0.7.6/terraform-provider-k8s_0.7.6_darwin_amd64.tar.gz | tar xvz - -C ~/.terraform.d/plugins
```

#### TODO:
* Add private VPC endpoints for AWS Services required by ALB ingress controller.
* incorporate k8s RBAC policies