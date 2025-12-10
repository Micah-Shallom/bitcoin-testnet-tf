#!/bin/bash
set -e

# Log all output for debugging
exec > >(tee /var/log/bitcoin-setup.log)
exec 2>&1

echo "=== Starting Bitcoin Setup (Ubuntu 20.04) ==="
echo "Timestamp: $(date)"

# --- Variables from Terraform ---
# We use these to inject the specific version and network settings
# The user's guide uses exports, but we can set them directly here for the script context.

# Note: The guide hardcodes 0.21.1, but we should use the terraform variable if possible 
# to keep it flexible, OR strict follow the guide. 
# Best practice: Use the Terraform value but default to strict guide paths.

BITCOIN_VERSION="${bitcoin_version}"
RPC_USER="${rpc_user}"
RPC_PASSWORD="${rpc_password}"
NETWORK="${network}"

echo "Configuration:"
echo "  Version: ${bitcoin_version}"
echo "  Network: ${network}"

# --- Environment Setup (from guide) ---
export ARCH=x86_64
export BITCOIN_URL="https://bitcoincore.org/bin/bitcoin-core-${bitcoin_version}/bitcoin-${bitcoin_version}-$ARCH-linux-gnu.tar.gz"
# The guide uses /blockchain/bitcoin/data. We must ensure our EBS volume is mounted there.
export BITCOIN_DATA_DIR=/blockchain/bitcoin/data

# --- EBS Volume Management ---
# We need to mount the EBS volume to /blockchain/bitcoin/data BEFORE unrelated steps
# because the guide expects this path to exist for permissions.
echo "=== Configuring Storage ==="

# Wait for device
# Nitro instances use nvme, older use xvd*
DEVICE_NAME=""
for dev in /dev/nvme1n1 /dev/xvdf /dev/sdf; do
    if [ -e "$dev" ]; then
        DEVICE_NAME="$dev"
        break
    fi
done

if [ -z "$DEVICE_NAME" ]; then
    # Wait loop
    echo "Device not found immediately, waiting..."
    MAX_WAIT=60
    COUNTER=0
    while [ $COUNTER -lt $MAX_WAIT ]; do
        for dev in /dev/nvme1n1 /dev/xvdf /dev/sdf; do
            if [ -e "$dev" ]; then
                DEVICE_NAME="$dev"
                break 2
            fi
        done
        sleep 2
        COUNTER=$((COUNTER + 1))
    done
fi

if [ -z "$DEVICE_NAME" ]; then
    echo "ERROR: Storage device not found!"
    exit 1
fi
echo "Found device: $DEVICE_NAME"

# Format if needed
if ! file -s "$DEVICE_NAME" | grep -q "ext4"; then
    mkfs -t ext4 "$DEVICE_NAME"
fi

# Mount path from guide
mkdir -p /blockchain/bitcoin/data
mount "$DEVICE_NAME" /blockchain/bitcoin/data

# Persistent mount
UUID=$(blkid -s UUID -o value "$DEVICE_NAME")
if ! grep -q "$UUID" /etc/fstab; then
    echo "UUID=$UUID /blockchain/bitcoin/data ext4 defaults,nofail 0 2" >> /etc/fstab
fi

# --- Installation (from guide) ---

echo "=== Creating user ==="
groupadd -r bitcoin || true
# -f in case user exists
useradd -r -m -g bitcoin -s /bin/bash bitcoin || true

echo "=== System Updates & Deps ==="
apt-get update
# The guide uses minimal deps, which is good.
apt-get install -y ca-certificates gnupg gpg wget jq --no-install-recommends

echo "=== Downloading Bitcoin Core ==="
cd /tmp
wget "https://bitcoincore.org/bin/bitcoin-core-${bitcoin_version}/SHA256SUMS"
wget "https://bitcoincore.org/bin/bitcoin-core-${bitcoin_version}/SHA256SUMS.asc"
wget -qO "bitcoin-${bitcoin_version}-$ARCH-linux-gnu.tar.gz" "$BITCOIN_URL"

# Verify checksum
echo "Verifying checksum..."
grep "bitcoin-${bitcoin_version}-$ARCH-linux-gnu.tar.gz" SHA256SUMS | sha256sum -c -

echo "=== Extracting ==="
mkdir -p "/opt/bitcoin/${bitcoin_version}"
mkdir -p "$BITCOIN_DATA_DIR"

# --exclude=*-qt strips GUI as per guide
tar -xzvf "bitcoin-${bitcoin_version}-$ARCH-linux-gnu.tar.gz" \
    -C "/opt/bitcoin/${bitcoin_version}" \
    --strip-components=1 \
    --exclude=*-qt

# Symlink current
ln -sfn "/opt/bitcoin/${bitcoin_version}" /opt/bitcoin/current
rm -rf /tmp/*

# Ownership
chown -R bitcoin:bitcoin "$BITCOIN_DATA_DIR"

# --- Configuration (from guide) ---
echo "=== Configuring bitcoin.conf ==="
# Generate password if not set
if [ -z "$RPC_PASSWORD" ]; then
    RPC_PASSWORD=$(openssl rand -hex 24)
fi

# Note: Guide creates bitcoin.conf.tmp then moves it.
cat > bitcoin.conf.tmp << EOF
datadir=$BITCOIN_DATA_DIR
printtoconsole=1
rpcallowip=127.0.0.1
rpcuser=$RPC_USER
rpcpassword=$RPC_PASSWORD
testnet=1
# Prune specific to guide's request, ensuring not too large
prune=1000
[test]
rpcbind=127.0.0.1
rpcport=18332
EOF

mv bitcoin.conf.tmp "$BITCOIN_DATA_DIR/bitcoin.conf"
chown bitcoin:bitcoin "$BITCOIN_DATA_DIR/bitcoin.conf"
chown -R bitcoin "$BITCOIN_DATA_DIR"

# Link home dir (users expect ~/.bitcoin to work)
# The guide does this:
ln -sfn "$BITCOIN_DATA_DIR" /home/bitcoin/.bitcoin
chown -h bitcoin:bitcoin /home/bitcoin
chown -R bitcoin:bitcoin /home/bitcoin


# --- Systemd (from guide) ---
echo "=== Systemd setup ==="
cat > bitcoind.service << EOF
[Unit]
Description=Bitcoin Core Testnet
After=network.target

[Service]
User=bitcoin
Group=bitcoin
WorkingDirectory=$BITCOIN_DATA_DIR
Type=simple
ExecStart=/opt/bitcoin/current/bin/bitcoind -conf=$BITCOIN_DATA_DIR/bitcoin.conf

[Install]
WantedBy=multi-user.target
EOF

mv bitcoind.service /etc/systemd/system/bitcoind.service
systemctl daemon-reload
systemctl enable bitcoind
systemctl start bitcoind

# --- Final touches ---
# Add to path for bitcoin user
echo 'export PATH=$PATH:/opt/bitcoin/current/bin' >> /home/bitcoin/.profile

echo "=== Setup Complete ==="
echo "Check logs: sudo journalctl -fu bitcoind"