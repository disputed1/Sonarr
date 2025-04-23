#!/bin/bash
### Sonarr Pterodactyl Install Script

scriptversion="1.0.9"
scriptdate="2025-04-23"

set -euo pipefail

echo "Running Sonarr Install Script - Version [$scriptversion] as of [$scriptdate]"

app="sonarr"
branch="main"
installdir="/home/container/sonarr"
datadir="/home/container/sonarr/data"
app_bin="Sonarr"  # Correct binary name

# Ensure required directories exist
echo "Creating Sonarr installation directory..."
mkdir -p "$installdir"
mkdir -p "$datadir"

# Install `curl` manually if missing
if ! command -v curl &> /dev/null; then
    echo "Installing curl manually..."
    cd /tmp
    wget http://ftp.us.debian.org/debian/pool/main/c/curl/curl_7.88.1-1_amd64.deb
    dpkg -i curl_7.88.1-1_amd64.deb
fi

# Determine download URL based on architecture
ARCH=$(dpkg --print-architecture)
dlbase="https://services.sonarr.tv/v1/download/$branch/latest?version=4&os=linux"
case "$ARCH" in
    "amd64") DLURL="${dlbase}&arch=x64" ;;
    "armhf") DLURL="${dlbase}&arch=arm" ;;
    "arm64") DLURL="${dlbase}&arch=arm64" ;;
    *)
        echo "ERROR: Architecture [$ARCH] not supported."
        exit 1
        ;;
esac

echo "Download URL: $DLURL"

# Download and extract Sonarr
echo "Downloading Sonarr..."
wget --content-disposition "$DLURL"
echo "Extracting Sonarr..."
tar -xvzf "Sonarr.*.tar.gz" --strip-components=1 -C "$installdir"
rm -f "Sonarr.*.tar.gz"

# Create Sonarr user to avoid permission errors
echo "Creating Sonarr user..."
useradd -m -s /usr/sbin/nologin sonarr || echo "User already exists."
groupadd media || true
usermod -aG media sonarr

# Apply correct permissions
echo "Setting permissions for $installdir..."
chmod -R 775 "$installdir"
chown -R sonarr:media "$installdir"

# Ensure logs directory exists
mkdir -p /home/container/logs
touch /home/container/logs/sonarr.log

# Start Sonarr after installation
echo "Starting Sonarr..."
exec /home/container/sonarr/Sonarr --nobrowser --data="$datadir" --port=8989 &

echo "Installation complete. Sonarr is running. You can access it at http://<your-ip>:8989"
exit 0
