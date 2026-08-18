module "network" {
  source = "../../modules/network"

  vpc_cidr = var.vpc_cidr
  region   = var.region

  tags = {
    Project     = "terraform-eks-dev"
    Environment = "dev"
  }
}

module "eks" {
  source = "../../modules/eks"

  cluster_name                = var.cluster_name
  region                      = var.region
  vpc_id                      = module.network.vpc_id
  subnet_ids                  = module.network.private_subnet_ids
  endpoint_public_access_cidrs = var.endpoint_public_access_cidrs
  node_instance_type          = var.node_instance_type
  node_desired_capacity       = var.node_desired_capacity
  node_min_capacity           = var.node_min_capacity
  node_max_capacity           = var.node_max_capacity
  log_retention_days          = var.log_retention_days

  tags = {
    Project     = "terraform-eks-dev"
    Environment = "dev"
  }
}

module "ingress" {
  source = "../../modules/ingress"

  cluster_name         = module.eks.cluster_name
  cluster_oidc_issuer  = module.eks.cluster_oidc_issuer_url
  vpc_id               = module.network.vpc_id
  region               = var.region
  lbc_chart_version    = var.lbc_chart_version

  tags = {
    Project     = "terraform-eks-dev"
    Environment = "dev"
  }
}
