resource "aws_security_group" "bitcoin_node" {
  name        = "${var.project_name}-sg"
  description = "Security group for Bitcoin testnet node"

  tags = {
    Name        = "${var.project_name}-sg"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# SSH access
resource "aws_security_group_rule" "ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.allowed_ssh_cidrs
  security_group_id = aws_security_group.bitcoin_node.id
  description       = "SSH access"
}

# Bitcoin Testnet P2P
resource "aws_security_group_rule" "bitcoin_testnet" {
  type              = "ingress"
  from_port         = 18333
  to_port           = 18333
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bitcoin_node.id
  description       = "Bitcoin Testnet P2P"
}

# Bitcoin Mainnet P2P (included for future flexibility)
resource "aws_security_group_rule" "bitcoin_mainnet" {
  type              = "ingress"
  from_port         = 8333
  to_port           = 8333
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bitcoin_node.id
  description       = "Bitcoin Mainnet P2P (disabled by default)"
}

# Lightning Network
resource "aws_security_group_rule" "lightning" {
  type              = "ingress"
  from_port         = 9735
  to_port           = 9735
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bitcoin_node.id
  description       = "Lightning Network"
}

# Allow all outbound traffic
resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bitcoin_node.id
  description       = "Allow all outbound traffic"
}