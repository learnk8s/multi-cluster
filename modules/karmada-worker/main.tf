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

variable "network_name" {
  description = "The network name"
}

variable "certs" {
  type = map(string)
}

variable "karmada_config" {
  type = string
}

resource "kubernetes_namespace" "istio" {
  metadata {
    name = local.istio_namespace

    labels = {
      "topology.istio.io/network" = var.network_name
    }
  }
}

resource "kubernetes_secret" "cacerts" {
  metadata {
    name      = "cacerts"
    namespace = local.istio_namespace
  }

  data = var.certs
}

resource "helm_release" "istio_base" {
  depends_on = [kubernetes_secret.cacerts, kubernetes_namespace.istio]
  name       = "istio-base"
  chart      = "https://istio-release.storage.googleapis.com/charts/base-1.14.1.tgz"
  # chart      = "istio/base"
  namespace = local.istio_namespace
}

resource "helm_release" "istiod" {
  depends_on = [kubernetes_secret.cacerts, kubernetes_namespace.istio]
  name       = "istiod"
  chart      = "https://istio-release.storage.googleapis.com/charts/istiod-1.14.1.tgz"
  # chart      = "istio/istiod"
  namespace = local.istio_namespace

  set {
    name  = "global.meshID"
    value = "mesh1"
  }

  set {
    name  = "global.multiCluster.clusterName"
    value = var.cluster_name
  }

  set {
    name  = "global.network"
    value = var.network_name
  }
}

# Wait for the mutating webhook to be available
resource "time_sleep" "wait_for_webhook" {
  depends_on = [helm_release.istiod]

  create_duration = "30s"
}

resource "helm_release" "eastwest_gateway" {
  depends_on = [time_sleep.wait_for_webhook]
  name       = "eastwest-gateway"
  chart      = "https://istio-release.storage.googleapis.com/charts/gateway-1.14.1.tgz"
  # chart      = "istio/gateway"
  namespace = local.istio_namespace

  set {
    name  = "labels.istio"
    value = "eastwestgateway"
  }

  set {
    name  = "labels.app"
    value = "istio-eastwestgateway"
  }

  set {
    name  = "labels.topology\\.istio\\.io/network"
    value = var.network_name
  }

  set {
    name  = "networkGateway"
    value = var.network_name
  }

  set {
    name  = "service.ports[0].name"
    value = "status-port"
  }
  set {
    name  = "service.ports[0].port"
    value = 15021
  }
  set {
    name  = "service.ports[0].targetPort"
    value = 15021
  }

  set {
    name  = "service.ports[1].name"
    value = "tls"
  }
  set {
    name  = "service.ports[1].port"
    value = 15443
  }
  set {
    name  = "service.ports[1].targetPort"
    value = 15443
  }

  set {
    name  = "service.ports[2].name"
    value = "tls-istiod"
  }
  set {
    name  = "service.ports[2].port"
    value = 15012
  }
  set {
    name  = "service.ports[2].targetPort"
    value = 15012
  }

  set {
    name  = "service.ports[3].name"
    value = "tls-webhook"
  }
  set {
    name  = "service.ports[3].port"
    value = 15017
  }
  set {
    name  = "service.ports[3].targetPort"
    value = 15017
  }
}

resource "helm_release" "ingress_gateway" {
  depends_on = [time_sleep.wait_for_webhook]
  name       = "ingress-gateway"
  chart      = "https://istio-release.storage.googleapis.com/charts/gateway-1.14.1.tgz"
  # chart      = "istio/gateway"
  namespace = local.istio_namespace

  set {
    name  = "labels.istio"
    value = "ingressgateway"
  }

  set {
    name  = "labels.app"
    value = "istio-ingressgateway"
  }

  set {
    name  = "labels.topology\\.istio\\.io/network"
    value = var.network_name
  }
}

resource "helm_release" "karmada" {
  name             = "karmada"
  chart            = "https://github.com/karmada-io/karmada/releases/download/v1.2.0/karmada-chart-v1.2.0.tgz"
  namespace        = "karmada"
  create_namespace = true

  set {
    name  = "installMode"
    value = "agent"
  }

  set {
    name  = "agent.clusterName"
    value = var.cluster_name
  }

  set {
    name  = "agent.kubeconfig.caCrt"
    value = base64decode(yamldecode(file(var.karmada_config)).clusters[0].cluster["certificate-authority-data"])
  }

  set {
    name  = "agent.kubeconfig.crt"
    value = base64decode(yamldecode(file(var.karmada_config)).users[0].user["client-certificate-data"])
  }

  set {
    name  = "agent.kubeconfig.key"
    value = base64decode(yamldecode(file(var.karmada_config)).users[0].user["client-key-data"])
  }

  set {
    name  = "agent.kubeconfig.server"
    value = yamldecode(file(var.karmada_config)).clusters[0].cluster.server
  }
}

resource "kubernetes_labels" "this" {
  api_version = "v1"
  kind        = "Namespace"
  metadata {
    name = "default"
  }
  labels = {
    "istio-injection" = "enabled"
  }
}

# https://medium.com/@danieljimgarcia/dont-use-the-terraform-kubernetes-manifest-resource-6c7ff4fe629a
resource "null_resource" "expose" {
  triggers = {
    invokes_me_everytime = uuid()
    kubeconfig_path      = var.kubeconfig_path
    current_path         = path.module
    istio_namespace      = local.istio_namespace
  }

  provisioner "local-exec" {
    command = "kubectl apply --kubeconfig=${var.kubeconfig_path} -n ${local.istio_namespace} -f ${path.module}/expose.yaml"
  }

  # https://github.com/hashicorp/terraform/issues/23679#issuecomment-885063851
  provisioner "local-exec" {
    command = "kubectl delete --kubeconfig=${self.triggers.kubeconfig_path} -n ${self.triggers.istio_namespace} --ignore-not-found=true -f ${self.triggers.current_path}/expose.yaml"
    when    = destroy
  }
  depends_on = [helm_release.eastwest_gateway, helm_release.ingress_gateway]
}
