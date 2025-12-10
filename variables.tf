variable "aws_region" {
  description = "AWS region to deploy the Bitcoin node"
  type        = string
  default     = "us-east-1"
}

variable "availability_zone" {
  description = "AWS availability zone (must support t3.medium instances)"
  type        = string
  default     = "us-east-1a"
}

variable "project_name" {
  description = "Name of the project (used for tagging and naming resources)"
  type        = string
  default     = "bitcoin-testnet-node"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "instance_type" {
  description = "EC2 instance type (minimum t3.medium recommended)"
  type        = string
  default     = "t3.medium"
}

variable "key_pair_name" {
  description = "Name of the AWS key pair to use for SSH access"
  type        = string
}

variable "ebs_volume_size" {
  description = "Size of EBS volume in GB for blockchain data (300GB recommended for testnet)"
  type        = number
  default     = 300
}

variable "bitcoin_version" {
  description = "Bitcoin Core version to install"
  type        = string
  default     = "27.0"
}

variable "rpc_user" {
  description = "Bitcoin RPC username"
  type        = string
  default     = "bitcoinrpc"
}

variable "rpc_password" {
  description = "Bitcoin RPC password (leave empty to auto-generate)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "create_elastic_ip" {
  description = "Whether to create and associate an Elastic IP (recommended for persistent access)"
  type        = bool
  default     = true
}

variable "allowed_ssh_cidrs" {
  description = "List of CIDR blocks allowed to SSH into the instance"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "max_connections" {
  description = "Maximum number of Bitcoin peer connections"
  type        = number
  default     = 16
}

variable "dbcache" {
  description = "Database cache size in MB"
  type        = number
  default     = 1536
}

variable "network" {
  description = "Bitcoin network to use (mainnet, testnet, regtest)"
  type        = string
  default     = "testnet"
}