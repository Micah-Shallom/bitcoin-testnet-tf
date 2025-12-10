output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.bitcoin_node.id
}

output "instance_public_ip" {
  description = "Public IP address of the instance"
  value       = var.create_elastic_ip ? aws_eip.bitcoin_node[0].public_ip : aws_instance.bitcoin_node.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the instance"
  value       = aws_instance.bitcoin_node.private_ip
}

output "elastic_ip" {
  description = "Elastic IP address (if created)"
  value       = var.create_elastic_ip ? aws_eip.bitcoin_node[0].public_ip : "Not created"
}

output "ssh_connection_command" {
  description = "Command to SSH into the instance"
  value       = "ssh -i /path/to/${var.key_pair_name}.pem admin@${var.create_elastic_ip ? aws_eip.bitcoin_node[0].public_ip : aws_instance.bitcoin_node.public_ip}"
}

output "bitcoin_rpc_user" {
  description = "Bitcoin RPC username"
  value       = var.rpc_user
}

output "bitcoin_rpc_password" {
  description = "Bitcoin RPC password"
  value       = var.rpc_password != "" ? var.rpc_password : "Auto-generated (check /home/admin/.bitcoin/bitcoin.conf on the instance)"
  sensitive   = true
}

output "ebs_volume_id" {
  description = "ID of the EBS volume"
  value       = aws_ebs_volume.bitcoin_data.id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.bitcoin_node.id
}

output "setup_status_command" {
  description = "Command to check Bitcoin setup status"
  value       = "ssh -i /path/to/${var.key_pair_name}.pem admin@${var.create_elastic_ip ? aws_eip.bitcoin_node[0].public_ip : aws_instance.bitcoin_node.public_ip} 'tail -f /var/log/cloud-init-output.log'"
}

output "bitcoin_cli_command" {
  description = "Example command to check Bitcoin node status"
  value       = "ssh -i /path/to/${var.key_pair_name}.pem admin@${var.create_elastic_ip ? aws_eip.bitcoin_node[0].public_ip : aws_instance.bitcoin_node.public_ip} 'bitcoin-cli -testnet getblockchaininfo'"
}