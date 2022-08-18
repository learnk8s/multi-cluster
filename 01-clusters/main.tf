module "cluster_manager" {
  source = "../modules/cluster"

  name   = "cluster-manager"
  region = "us-west"
}

resource "local_file" "kubeconfig_cluster_manager" {
  filename = "../kubeconfig-cluster-manager"
  content  = module.cluster_manager.kubeconfig
}

module "ap" {
  source = "../modules/cluster"

  name   = "ap"
  region = "ap-south"
}

resource "local_file" "kubeconfig_ap" {
  filename = "../kubeconfig-ap"
  content  = module.ap.kubeconfig
}

module "us" {
  source = "../modules/cluster"

  name   = "us"
  region = "us-west"
}

resource "local_file" "kubeconfig_us" {
  filename = "../kubeconfig-us"
  content  = module.us.kubeconfig
}

module "eu" {
  source = "../modules/cluster"

  name   = "eu"
  region = "eu-west"
}

resource "local_file" "kubeconfig_eu" {
  filename = "../kubeconfig-eu"
  content  = module.eu.kubeconfig
}
