terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.12.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.6.0"
    }
  }
}

locals {
  istio_namespace = "istio-system"
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}

variable "kubeconfig_path" {
  type = string
}

variable "cluster_name" {
  description = "The name for the cluster"
  type        = string
}

resource "helm_release" "prometheus" {
  name      = "prometheus"
  chart     = "https://github.com/prometheus-community/helm-charts/releases/download/prometheus-15.11.0/prometheus-15.11.0.tgz"
  namespace = local.istio_namespace

  set {
    name  = "server.global.scrape_interval"
    value = "10s"
  }

  set {
    name  = "server.global.evaluation_interval"
    value = "10s"
  }
}

# Kiali expects the server to be available on http://prometheus.istio-system:9090
# The value should be customizable in the Kiali ConfigMap, but the Helm chart does not expose it.
# `external_services`: https://kiali.io/docs/configuration/kialis.kiali.io/
# As a workaround, create the service.
resource "kubernetes_service" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = local.istio_namespace
  }
  spec {
    selector = {
      app       = "prometheus"
      component = "server"
      release   = "prometheus"
    }
    session_affinity = "ClientIP"
    port {
      port        = 9090
      target_port = 9090
    }

    type = "ClusterIP"
  }
  depends_on = [
    helm_release.prometheus
  ]
}

resource "helm_release" "kiali_server" {
  name      = "kiali-server"
  chart     = "https://kiali.org/helm-charts/kiali-server-1.54.0.tgz"
  namespace = local.istio_namespace
  depends_on = [
    helm_release.prometheus
  ]

  set {
    name  = "istio.root_namespace"
    value = local.istio_namespace
  }
}

data "kubernetes_service_account" "this" {
  metadata {
    name      = "kiali"
    namespace = local.istio_namespace
  }
  depends_on = [
    helm_release.kiali_server
  ]
}

data "kubernetes_secret" "this" {
  metadata {
    name      = data.kubernetes_service_account.this.default_secret_name
    namespace = local.istio_namespace
  }
}

output "token" {
  value = nonsensitive(data.kubernetes_secret.this.data)["token"]
}
