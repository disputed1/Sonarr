#!/bin/bash
### Sonarr .NET Debian Install Script

scriptversion="1.0.6"
scriptdate="2025-04-23"

set -euo pipefail

echo "Running Sonarr Install Script - Version [$scriptversion] as of [$scriptdate]"

# Ensure we are running as root
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: This script must be run as root."
    exit 1
fi

app="sonarr"
branch="main"
installdir="/home/container/sonarr"
datadir="/home/container/sonarr/data"
app_bin="Sonarr"  # Correct binary name

# Create installation directory and navigate to it
echo "Creating installation directory: $installdir..."
mkdir -p "$installdir"
cd "$installdir"

# Install `wget` manually in a writable location
echo "Installing wget in a writable path..."
cd /tmp
curl -o wget.deb http://ftp.us.debian.org/debian/pool/main/w/wget/wget_1.21.3-1_amd64.deb
dpkg -i wget.deb
cd "$installdir"

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

# Create the required `sonarr` user to avoid permission errors
echo "Creating Sonarr user..."
useradd -m -s /usr/sbin/nologin sonarr || echo "User already exists."
groupadd media || true
usermod -aG media sonarr

# Apply correct permissions
echo "Setting permissions for $installdir..."
chmod -R 775 "$installdir"
chown -R sonarr:media "$installdir"

# Ensure the data directory exists
echo "Ensuring data directory exists..."
mkdir -p "$datadir"

echo "Installation complete. Sonarr is ready to start via Pterodactyl."
exit 0
