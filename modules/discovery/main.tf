terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.12.1"
    }
  }
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

variable "istio_namespace" {
  type    = string
  default = "istio-system"
}

variable "kubeconfig_path" {
  type = string
}

variable "cluster_name" {
  description = "The name for the cluster"
  type        = string
}

variable "cluster_discovery" {
  type = map(object({ cluster_name = string, kubeconfig_path = string }))
}

resource "kubernetes_secret" "this" {
  for_each = var.cluster_discovery

  metadata {
    name = "istio-remote-secret-${each.value.cluster_name}"

    annotations = {
      "networking.istio.io/cluster" = each.value.cluster_name
    }

    labels = {
      "istio/multiCluster" = "true"
    }

    namespace = var.istio_namespace
  }

  data = {
    "${each.value.cluster_name}" = file(each.value.kubeconfig_path)
  }
}
