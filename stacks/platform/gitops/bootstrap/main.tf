# Platform config the KRO RGDs read at reconcile time (externalRef data source).
# Holds the ArgoCD capability role ARN so the EKSCluster RGD can grant each new
# spoke's AccessEntry to it — resolved in-cluster, not injected at render.
resource "kubectl_manifest" "platform_config" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "ConfigMap"
    metadata = {
      name      = "platform-config"
      namespace = "kube-system"
    }
    data = {
      argocdRoleArn = var.argocd_role_arn
    }
  })
}

# ArgoCD app-of-apps.
resource "kubectl_manifest" "argocd_local_cluster" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Secret"
    metadata = {
      name      = "in-cluster"
      namespace = "argocd"
      labels    = { "argocd.argoproj.io/secret-type" = "cluster" }
    }
    stringData = {
      name    = "in-cluster"
      server  = var.cluster_arn
      project = "default"
    }
  })
}

resource "kubectl_manifest" "argocd_root_app" {
  yaml_body = templatefile("${path.module}/root-app.yaml.tftpl", {
    manifests_repo = var.manifests_repo
    manifests_tag  = var.manifests_tag
  })
  depends_on = [kubectl_manifest.argocd_local_cluster]
}
