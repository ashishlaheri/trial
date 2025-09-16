#!/bin/bash
# Puppet Master Installation Script
# Run as root or with sudo

set -e

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

echo "📦 Installing Puppet Master..."
wget -q "https://apt.puppetlabs.com/$RELEASE"
dpkg -i "$RELEASE"
apt-get update -y
apt-get install -y puppet-master

echo "⚙️ Configuring Puppet Master..."
# Ensure JAVA_ARGS exists
if grep -q "^JAVA_ARGS=" /etc/default/puppet-master; then
  sed -i 's/^JAVA_ARGS=.*/JAVA_ARGS="-Xms512m -Xmx512m"/' /etc/default/puppet-master
else
  echo 'JAVA_ARGS="-Xms512m -Xmx512m"' >> /etc/default/puppet-master
fi

echo "🔄 Restarting Puppet Master..."
systemctl restart puppet-master.service

# Open firewall port if ufw exists
if command -v ufw >/dev/null 2>&1; then
  ufw allow 8140/tcp || true
else
  echo "⚠️ UFW not installed, make sure AWS Security Group allows port 8140."
fi

echo "✅ Puppet Master installation complete!"
