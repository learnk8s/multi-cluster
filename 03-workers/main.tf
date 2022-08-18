module "worker_ap" {
  source = "../modules/karmada-worker"

  cluster_name    = "ap"
  kubeconfig_path = abspath("../kubeconfig-ap")
  certs = {
    "ca-cert.pem"    = file("../certs/cluster1/ca-cert.pem")
    "ca-key.pem"     = file("../certs/cluster1/ca-key.pem")
    "root-cert.pem"  = file("../certs/cluster1/root-cert.pem")
    "cert-chain.pem" = file("../certs/cluster1/cert-chain.pem")
  }
  network_name   = "network1"
  karmada_config = abspath("../karmada-config")
}

module "worker_us" {
  source = "../modules/karmada-worker"

  cluster_name    = "us"
  kubeconfig_path = abspath("../kubeconfig-us")
  certs = {
    "ca-cert.pem"    = file("../certs/cluster2/ca-cert.pem")
    "ca-key.pem"     = file("../certs/cluster2/ca-key.pem")
    "root-cert.pem"  = file("../certs/cluster2/root-cert.pem")
    "cert-chain.pem" = file("../certs/cluster2/cert-chain.pem")
  }
  network_name   = "network2"
  karmada_config = abspath("../karmada-config")
}

module "worker_eu" {
  source = "../modules/karmada-worker"

  cluster_name    = "eu"
  kubeconfig_path = abspath("../kubeconfig-eu")
  certs = {
    "ca-cert.pem"    = file("../certs/cluster3/ca-cert.pem")
    "ca-key.pem"     = file("../certs/cluster3/ca-key.pem")
    "root-cert.pem"  = file("../certs/cluster3/root-cert.pem")
    "cert-chain.pem" = file("../certs/cluster3/cert-chain.pem")
  }
  network_name   = "network3"
  karmada_config = abspath("../karmada-config")
}
