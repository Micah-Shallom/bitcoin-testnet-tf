# Bitcoin Testnet Node on AWS

Terraform configuration to deploy a Bitcoin Core testnet node on AWS EC2 with persistent EBS storage.

**Features:**
- One-command deployment with cloud-init automation
- Persistent EBS volume (preserves blockchain data across instance replacement)
- Encrypted storage, security groups, systemd auto-restart
- RPC over localhost only; secure by default

## Setup

### 1. Configure

```bash
git clone <your-repo>
cd bitcoin-testnet-tf
```

Edit `terraform.tfvars`:
```hcl
key_pair_name       = "your-aws-keypair"    # Required
aws_region          = "us-east-1"
instance_type       = "t3.medium"
ebs_volume_size     = 300                   # GB
bitcoin_version     = "27.0"
allowed_ssh_cidrs   = ["YOUR_IP/32"]        # Replace with your public IP
```

### 2. Deploy

```bash
terraform init
terraform apply -var-file=terraform.tfvars
```

### 3. Connect

```bash
ssh -i ~/path/to/key.pem admin@$(terraform output -raw instance_public_ip)

# Monitor setup (takes ~5-10 min)
tail -f /var/log/bitcoin-setup.log
```

## Usage

**Check Bitcoin status:**
```bash
sudo su - bitcoin
bitcoin-cli -testnet getblockchaininfo
```

**View service logs:**
```bash
sudo journalctl -fu bitcoind
```

**Pause instance (keep data, save $30/month):**
```bash
terraform destroy -var-file=terraform.tfvars
# EBS volume + IP preserved (prevent_destroy = true in main.tf)
```

**Resume:**
```bash
terraform apply -var-file=terraform.tfvars
# Syncs only new blocks (~5-15 min instead of 4-8 hours)
```


## Costs & Pause Strategy

**Always-on (24/7):** ~$54/month
- t3.medium EC2: $30/month
- 300GB EBS: $24/month

**Part-time (8h/day, 5d/week):** ~$34/month (37% savings)
- Instance only when in use: $10/month
- EBS storage (always): $24/month

| Setup | Deploy Time | Sync Time | Monthly Cost |
|-------|------------|-----------|--------------|
| Always On | — | Continuous | $54 |
| Fresh Spin-up | 3 min | 4–8 hours | $54 |
| Pause & Resume (preserved data) | 3 min | 5–15 min | $34 |

**How it works:**
1. Destroy instance when done: `terraform destroy` (EBS + IP preserved)
2. Data stays on EBS volume (prevent_destroy = true in main.tf)
3. Redeploy later: `terraform apply` (attaches same data, fast sync)

## Security

- ✅ EBS volumes encrypted by default
- ✅ RPC bound to localhost only
- ✅ SSH restricted by CIDR (set `allowed_ssh_cidrs` to your IP)
- ✅ Bitcoin runs as non-root `bitcoin` user
- ⚠️ Update `allowed_ssh_cidrs` in `terraform.tfvars` before deploying

## Variables Reference

| Variable | Default | Notes |
|----------|---------|-------|
| `bitcoin_version` | 27.0 | Core version |
| `instance_type` | t3.medium | Minimum recommended |
| `ebs_volume_size` | 300 | GB for testnet |
| `rpc_password` | "" | Auto-generated if empty |
| `allowed_ssh_cidrs` | ["0.0.0.0/0"] | **Change to your IP/32** |

## References

- [Bitcoin Core](https://bitcoincore.org/)
- [Terraform Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
