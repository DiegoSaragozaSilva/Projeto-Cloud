# AWS provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.14.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Kubernets provider
provider "kubernetes" {
  host                   = module.EKS.cluster_endpoint
  cluster_ca_certificate = base64decode(module.EKS.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    command     = "aws"
    args = ["eks", "get-token", "--cluster-name", module.EKS.cluster_id]
  }
}

data "aws_availability_zones" "zones" {}

# Create the main VPC
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "MainVPC"
  cidr = "192.168.0.0/16"

  azs             = data.aws_availability_zones.zones.names
  public_subnets  = ["192.168.0.0/24", "192.168.1.0/24"]

  enable_nat_gateway   = true
  enable_dns_hostnames = true

  map_public_ip_on_launch = true

  tags = {
    Name = "MainVPC"
  }
}

resource "aws_security_group" "MainSecurityGroup" {
  name        = "MainSecurityGroup"
  description = "Allow all ingress and egress"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description      = "All"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description = "All"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "MainSecurityGroup"
  }
}

# EKS
module "EKS"{
  source = "terraform-aws-modules/eks/aws"
  version = "~> 18.21.0"

  cluster_name = "EKSCluster"
  cluster_version = "1.22"
  
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access = true
  
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets
  
  manage_aws_auth_configmap = true

  create_cluster_security_group = false
  cluster_security_group_id = aws_security_group.MainSecurityGroup.id

  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = ["t2.medium"]
    disk_size      = 32
  }

  eks_managed_node_groups = {
    MainNodeGroup = {
      instance_types = ["t2.medium"]
      
      min_size     = 3
      max_size     = 3
      desired_size = 3

      subnet_ids = module.vpc.public_subnets

      associate_public_ip_address = true
    }
  }

  tags = {
      Name = "EKSCluster"
  }

}

data "aws_eks_cluster" "cluster" {
    name = module.EKS.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
    name = module.EKS.cluster_id
}