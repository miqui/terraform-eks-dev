module "network" {
  source = "../../modules/network"

  vpc_cidr = var.vpc_cidr
  region   = var.region

  tags = {
    Project     = "terraform-eks-dev"
    Environment = "dev"
  }
}

# Auto-detect local public IP for the cluster endpoint allowlist
data "http" "local_public_ip" {
  url = "https://api.ipify.org"
}

locals {
  endpoint_public_access_cidrs = length(var.endpoint_public_access_cidrs) > 0 ? var.endpoint_public_access_cidrs : ["${chomp(data.http.local_public_ip.response_body)}/32"]
}

module "eks" {
  source = "../../modules/eks"

  cluster_name                = var.cluster_name
  region                      = var.region
  vpc_id                      = module.network.vpc_id
  subnet_ids                  = module.network.private_subnet_ids
  endpoint_public_access_cidrs = local.endpoint_public_access_cidrs
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

module "rds" {
  source = "../../modules/rds"

  vpc_id                  = module.network.vpc_id
  private_subnet_ids      = module.network.private_subnet_ids
  allowed_security_group_id = module.eks.node_security_group_id
  db_instance_class       = var.db_instance_class
  db_engine               = "postgres"
  db_engine_version       = "16"
  db_name                 = var.db_name
  db_username             = var.db_username
  deletion_protection     = false

  tags = {
    Project     = "terraform-eks-dev"
    Environment = "dev"
  }
}

module "iam_policy_rds" {
  source = "../../modules/iam-policy-rds"

  rds_instance_arn = module.rds.rds_arn
  rds_secret_arn   = module.rds.rds_secret_arn

  tags = {
    Project     = "terraform-eks-dev"
    Environment = "dev"
  }
}

module "app_iam" {
  source = "../../modules/app-iam"

  cluster_name        = module.eks.cluster_name
  cluster_oidc_issuer = module.eks.cluster_oidc_issuer_url
  app_sa_name         = "my-app-sa"
  app_sa_namespace    = "default"
  region              = var.region

  attached_policy_arns = [module.iam_policy_rds.policy_arn]

  secret_arn  = module.rds.rds_secret_arn
  secret_name = "app-db-credentials"

  tags = {
    Project     = "terraform-eks-dev"
    Environment = "dev"
  }
}
