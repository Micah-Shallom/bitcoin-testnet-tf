# Bitcoin Testnet Node on AWS

Terraform configuration to deploy a Bitcoin Core testnet node on AWS EC2 with persistent storage.

## Features

- 🚀 **Automated Setup** - One-command deployment of a fully configured Bitcoin testnet node
- 💾 **Persistent Storage** - Dedicated EBS volume for blockchain data (survives instance replacement)
- 🔒 **Secure** - Encrypted volumes, security groups, and systemd service management
- 📊 **Production Ready** - Systemd service with auto-restart, proper logging via journald
- ⚡ **Ubuntu 20.04** - Latest LTS with Bitcoin Core installed to `/opt/bitcoin`

## Architecture

- **EC2 Instance**: Ubuntu 20.04 LTS (t3.medium recommended)
- **Storage**: 300GB EBS volume mounted at `/blockchain/bitcoin/data`
- **Network**: Testnet with configurable pruning (default: 1GB)
- **Service**: Systemd-managed `bitcoind` service running as dedicated `bitcoin` user

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** >= 1.0 installed
3. **SSH Key Pair** created in AWS
4. **AWS CLI** configured (optional but recommended)

## Quick Start

### 1. Clone and Configure

```bash
git clone <your-repo>
cd bitcoin-testnet-tf
```

### 2. Create `terraform.tfvars`

```hcl
# Required
key_pair_name = "your-aws-keypair-name"

# Optional (defaults shown)
aws_region         = "us-east-1"
availability_zone  = "us-east-1a"
instance_type      = "t3.medium"
bitcoin_version    = "27.0"
network            = "testnet"
ebs_volume_size    = 300
```

### 3. Deploy

```bash
terraform init
terraform plan
terraform apply
```

### 4. Connect

After deployment completes, get the connection details:

```bash
terraform output ssh_connection_command
```

Example:

```bash
ssh -i /path/to/your-key.pem ubuntu@<elastic-ip>
```

## Verification

### Check Setup Progress

```bash
tail -f /var/log/bitcoin-setup.log
```

Look for: `=== Setup Complete ===`

### Check Bitcoin Service

```bash
sudo systemctl status bitcoind
```

### Check Sync Status

```bash
sudo su - bitcoin
bitcoin-cli -getinfo
```

Expected output:

```
Chain: test
Blocks: 445995
Headers: 4805575
Verification progress: ▒░░░░░░░░░░░░░░░░░░░░ 2.4%
```

### Monitor Logs

```bash
sudo journalctl -fu bitcoind
```

## Configuration

### Variables

| Variable          | Description                            | Default      |
| ----------------- | -------------------------------------- | ------------ |
| `bitcoin_version` | Bitcoin Core version                   | `27.0`       |
| `network`         | Network type (testnet/mainnet/regtest) | `testnet`    |
| `instance_type`   | EC2 instance type                      | `t3.medium`  |
| `ebs_volume_size` | Blockchain storage size (GB)           | `300`        |
| `rpc_user`        | RPC username                           | `bitcoinrpc` |
| `rpc_password`    | RPC password (auto-generated if empty) | `""`         |
| `dbcache`         | Database cache size (MB)               | `1536`       |
| `max_connections` | Max peer connections                   | `16`         |

### Bitcoin Configuration

The node is configured with:

- **Testnet mode** enabled
- **Pruning** set to 1GB (configurable in script)
- **Transaction index** enabled
- **RPC** bound to localhost only
- **Systemd** service for automatic restart

## File Structure

```
.
├── main.tf              # Main Terraform configuration
├── variables.tf         # Variable definitions
├── security_group.tf    # Network security rules
├── output.tf           # Output values
├── scripts/
│   └── user_data.sh    # Instance initialization script
└── terraform.tfvars    # Your configuration (gitignored)
```

## Maintenance

### Update Bitcoin Version

1. Update `bitcoin_version` in `terraform.tfvars`
2. Replace the instance:
   ```bash
   terraform apply -replace="aws_instance.bitcoin_node"
   ```

### View RPC Password

```bash
terraform output bitcoin_rpc_password
```

### Destroy Infrastructure

```bash
terraform destroy
```

**⚠️ Warning**: This will delete the instance but the EBS volume will be retained by default.

## Troubleshooting

### Instance Not Starting

Check cloud-init logs:

```bash
ssh ubuntu@<ip>
tail -f /var/log/cloud-init-output.log
```

### Bitcoin Not Syncing

Check bitcoind logs:

```bash
sudo journalctl -fu bitcoind
```

### SSH Host Key Changed

After replacing instances:

```bash
ssh-keygen -f ~/.ssh/known_hosts -R '<instance-ip>'
```

## Security Notes

- 🔒 EBS volumes are encrypted by default
- 🔒 RPC is bound to localhost only
- 🔒 Security group restricts SSH to specified CIDRs
- 🔒 Bitcoin runs as non-root `bitcoin` user
- ⚠️ Default SSH CIDR is `0.0.0.0/0` - **change this in production!**

## Costs

Approximate monthly costs (us-east-1):

- **t3.medium instance**: ~$30/month
- **300GB EBS gp3**: ~$24/month
- **Elastic IP**: Free (when attached)
- **Data transfer**: Varies

**Total**: ~$54/month

## License

MIT

## Contributing

Pull requests welcome! Please ensure Terraform formatting:

```bash
terraform fmt
```

## References

- [Bitcoin Core Documentation](https://bitcoin.org/en/bitcoin-core/)
- [Bitcoin Core Downloads](https://bitcoincore.org/bin/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
