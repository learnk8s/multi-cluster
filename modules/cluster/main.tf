terraform {
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "1.28.0"
    }
  }
}

variable "name" {
  type = string
}

variable "region" {
  type = string
}

resource "linode_lke_cluster" "this" {
  label       = var.name
  k8s_version = "1.23"
  region      = var.region

  pool {
    type  = "g6-standard-2"
    count = 1

    autoscaler {
      min = 1
      max = 10
    }
  }

  # Prevent the count field from overriding autoscaler-created nodes
  lifecycle {
    ignore_changes = [
      pool.0.count
    ]
  }
}

output "kubeconfig" {
  value     = base64decode(linode_lke_cluster.this.kubeconfig)
  sensitive = true
}
