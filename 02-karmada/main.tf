module "karmada" {
  source = "../modules/karmada-manager"

  kubeconfig_path = "../kubeconfig-cluster-manager"
}

resource "local_file" "karmada_config" {
  filename = "../karmada-config"
  content  = module.karmada.karmada_config
}