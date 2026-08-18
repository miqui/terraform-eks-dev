region   = "us-east-1"
cluster_name = "dev-eks-cluster"

# Restrict cluster endpoint to your IP — replace with your actual IP
# endpoint_public_access_cidrs = ["203.0.113.10/32"]
endpoint_public_access_cidrs = ["0.0.0.0/0"]

vpc_cidr = "10.0.0.0/16"

node_instance_type    = "t3.medium"
node_desired_capacity = 2
node_min_capacity     = 1
node_max_capacity     = 3

log_retention_days  = 7
lbc_chart_version   = "1.4.8"
