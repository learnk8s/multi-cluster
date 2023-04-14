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

  set {
    name  = "auth.strategy"
    value = "anonymous"
  }

  set {
    name  = "external_services.custom_dashboards.prometheus.url"
    value = "http://prometheus-server/"
  }

  set {
    name  = "external_services.prometheus.url"
    value = "http://prometheus-server"
  }
}
