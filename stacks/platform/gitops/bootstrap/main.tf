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
