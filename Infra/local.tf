locals {
  name                   = "dreams-vacation"
  cidr_block             = "10.0.0.0/16"
  private_subnets_blocks = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets_blocks  = ["10.0.3.0/24", "10.0.4.0/24"]
  azs                    = ["us-east-1a", "us-east-1b"]
  cluster_name           = "dreams-vacation-cluster"
}