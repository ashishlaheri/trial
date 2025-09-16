#!/bin/bash
# Puppet Slave (Agent) Installation Script
# Run as root or with sudo

set -e
MASTER_IP=$1

if [ -z "$MASTER_IP" ]; then
  echo "⚠️ No MASTER IP provided."
  echo "Attempting to auto-detect Master Private IP from default route..."
  MASTER_IP=$(ip route get 8.8.8.8 | awk '{print $7; exit}')
  if [ -z "$MASTER_IP" ]; then
    echo "❌ Could not auto-detect Master IP. Please run:"
    echo "   sudo ./install_slave.sh <MASTER_PRIVATE_IP>"
    exit 1
  else
    echo "✅ Auto-detected Master IP: $MASTER_IP"
  fi
fi

echo "🔄 Updating system..."
apt-get update -y
apt-get install -y wget lsb-release

# Detect Ubuntu Version
UBUNTU_CODENAME=$(lsb_release -cs)
echo "ℹ️ Detected Ubuntu version: $UBUNTU_CODENAME"

case "$UBUNTU_CODENAME" in
  bionic|focal|jammy)
    RELEASE="puppet-release-$UBUNTU_CODENAME.deb"
    ;;
  *)
    echo "⚠️ Unknown Ubuntu version. Defaulting to bionic package."
    RELEASE="puppet-release-bionic.deb"
    ;;
esac

echo "📦 Installing Puppet Agent..."
wget -q "https://apt.puppetlabs.com/$RELEASE"
dpkg -i "$RELEASE"
apt-get update -y
apt-get install -y puppet

# Update /etc/hosts safely
if ! grep -qxF "$MASTER_IP puppet" /etc/hosts; then
  echo "$MASTER_IP puppet" >> /etc/hosts
  echo "✅ Added '$MASTER_IP puppet' to /etc/hosts"
else
  echo "ℹ️ Entry already exists in /etc/hosts"
fi

systemctl start puppet
systemctl enable puppet

echo "✅ Puppet Slave installation complete!"
