terraform {
  required_version = ">= 1.5"

  backend "s3" {
    # Configure via terraform init -backend-config or override file
    # For ephemeral / local state fallback, comment out this block
    # and run: terraform init -reconfigure
    bucket = "terraform-eks-dev-state"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"

    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.26"
    }
  }
}
