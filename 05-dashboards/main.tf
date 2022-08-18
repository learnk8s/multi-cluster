module "worker_ap" {
  source = "../modules/dashboard"

  cluster_name    = "ap"
  kubeconfig_path = abspath("../kubeconfig-ap")
}

output "kiali_token_ap" {
  value = module.worker_ap.token
}

module "worker_us" {
  source = "../modules/dashboard"

  cluster_name    = "us"
  kubeconfig_path = abspath("../kubeconfig-us")
}

output "kiali_token_us" {
  value = module.worker_us.token
}

module "worker_eu" {
  source = "../modules/dashboard"

  cluster_name    = "eu"
  kubeconfig_path = abspath("../kubeconfig-eu")
}

output "kiali_token_eu" {
  value = module.worker_eu.token
}
