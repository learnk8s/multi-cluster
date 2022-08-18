module "worker_ap" {
  source = "../modules/discovery"

  cluster_name    = "ap"
  kubeconfig_path = abspath("../kubeconfig-ap")
  cluster_discovery = {
    "us" = { cluster_name = "us", kubeconfig_path = abspath("../kubeconfig-us") }
    "eu" = { cluster_name = "eu", kubeconfig_path = abspath("../kubeconfig-eu") }
  }
}

module "worker_us" {
  source = "../modules/discovery"

  cluster_name    = "us"
  kubeconfig_path = abspath("../kubeconfig-us")
  cluster_discovery = {
    "ap" = { cluster_name = "ap", kubeconfig_path = abspath("../kubeconfig-ap") }
    "eu" = { cluster_name = "eu", kubeconfig_path = abspath("../kubeconfig-eu") }
  }
}

module "worker_eu" {
  source = "../modules/discovery"

  cluster_name    = "eu"
  kubeconfig_path = abspath("../kubeconfig-eu")
  cluster_discovery = {
    "ap" = { cluster_name = "ap", kubeconfig_path = abspath("../kubeconfig-ap") }
    "us" = { cluster_name = "us", kubeconfig_path = abspath("../kubeconfig-us") }
  }
}
