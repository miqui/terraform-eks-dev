# DB subnet group in private subnets
resource "aws_db_subnet_group" "this" {
  name       = "terraform-eks-dev-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.tags, {
    Name = "terraform-eks-dev-db-subnet-group"
  })
}

# Security group — ingress on 5432 from EKS node SG only
resource "aws_security_group" "rds" {
  name        = "terraform-eks-dev-rds-sg"
  description = "Allow ingress from EKS nodes on port 5432"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from EKS nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.allowed_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "terraform-eks-dev-rds-sg"
  })
}

# RDS instance — AWS manages the master password via Secrets Manager
resource "aws_db_instance" "this" {
  engine                    = var.db_engine
  engine_version            = var.db_engine_version
  instance_class            = var.db_instance_class
  db_name                   = var.db_name
  username                  = var.db_username
  manage_master_user_password = true

  db_subnet_group_name      = aws_db_subnet_group.this.name
  vpc_security_group_ids    = [aws_security_group.rds.id]

  storage_type              = "gp3"
  allocated_storage         = 20

  skip_final_snapshot       = !var.deletion_protection
  deletion_protection       = var.deletion_protection
  publicly_accessible       = false
  backup_retention_period   = 1

  tags = merge(var.tags, {
    Name = "terraform-eks-dev-rds"
  })
}
