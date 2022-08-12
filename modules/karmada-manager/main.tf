terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "2.6.0"
    }
  }
}

variable "kubeconfig_path" {
  type = string
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}

locals {
  karmada_namespace  = "karmada-system"
  cluster_domain     = "cluster.local"
  hosts = [
    "kubernetes.default.svc",
    "*.etcd.${local.karmada_namespace}.svc.${local.cluster_domain}",
    "*.${local.karmada_namespace}.svc.${local.cluster_domain}",
    "*.${local.karmada_namespace}.svc",
    "localhost",
    "127.0.0.1",
    data.local_file.node_ip.content, # <- add the IP address of the Node hosting the Karmada API server
  ]
  karmada_api_nodeport = 32443
}

resource "null_resource" "get_node_ip" {
  provisioner "local-exec" {
    command = "kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type==\"ExternalIP\")].address}' --kubeconfig=${var.kubeconfig_path} > node_ip.txt"
  }
  provisioner "local-exec" {
    command = "rm -f node_ip.txt"
    when    = destroy
  }
}

data "local_file" "node_ip" {
  filename   = "node_ip.txt"
  depends_on = [null_resource.get_node_ip]
}

resource "helm_release" "karmada" {
  name             = "karmada"
  chart            = "https://github.com/karmada-io/karmada/releases/download/v1.2.0/karmada-chart-v1.2.0.tgz"
  namespace        = local.karmada_namespace
  create_namespace = true

  set {
    name  = "apiServer.hostNetwork"
    value = "false"
  }

  set {
    name  = "apiServer.serviceType"
    value = "NodePort"
  }

  set {
    name  = "apiServer.nodePort"
    value = local.karmada_api_nodeport
  }

  dynamic "set" {
    for_each = local.hosts
    content {
      name  = "certs.auto.hosts[${set.key}]"
      value = set.value
    }
  }
}

resource "null_resource" "karamada_kubeconfig" {
  provisioner "local-exec" {
    command = "kubectl get secret --kubeconfig=${var.kubeconfig_path} -n ${local.karmada_namespace} karmada-kubeconfig -o jsonpath={.data.kubeconfig} | base64 -d | sed -e 's/karmada-apiserver.${local.karmada_namespace}.svc.${local.cluster_domain}:5443/${data.local_file.node_ip.content}:${local.karmada_api_nodeport}/g' > karmada-config"
  }
  provisioner "local-exec" {
    command = "rm -f karmada-config"
    when    = destroy
  }
  depends_on = [helm_release.karmada]
}

data "local_file" "karmada_config" {
  filename   = "karmada-config"
  depends_on = [null_resource.karamada_kubeconfig]
}

output "node_ip" {
  value = data.local_file.node_ip.content
}

output "karmada_config" {
  value = data.local_file.karmada_config.content
  sensitive = true
}
