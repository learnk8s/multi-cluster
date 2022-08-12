module "worker_sg" {
  source = "../modules/discovery"

  cluster_name    = "sg"
  kubeconfig_path = abspath("../kubeconfig-sg")
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
    "sg" = { cluster_name = "sg", kubeconfig_path = abspath("../kubeconfig-sg") }
    "eu" = { cluster_name = "eu", kubeconfig_path = abspath("../kubeconfig-eu") }
  }
}

module "worker_eu" {
  source = "../modules/discovery"

  cluster_name    = "eu"
  kubeconfig_path = abspath("../kubeconfig-eu")
  cluster_discovery = {
    "sg" = { cluster_name = "sg", kubeconfig_path = abspath("../kubeconfig-sg") }
    "us" = { cluster_name = "us", kubeconfig_path = abspath("../kubeconfig-us") }
  }
}
