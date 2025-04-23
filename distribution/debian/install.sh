#!/bin/bash
### Description: Sonarr .NET Debian install

scriptversion="1.0.5"
scriptdate="2025-04-23"

set -euo pipefail

echo "Running Sonarr Install Script - Version [$scriptversion] as of [$scriptdate]"

# Ensure we are running as root
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: This script must be run as root."
    exit 1
fi

app="sonarr"
app_prereq="curl sqlite3 wget"
branch="main"

# Set installation and data directories
installdir="/home/container/sonarr"
datadir="/home/container/sonarr/data"
app_bin="Sonarr"  # Correct binary name

# Create installation directory and navigate to it
echo "Creating installation directory: $installdir..."
mkdir -p "$installdir"
cd "$installdir"

# Install required packages
echo "Installing dependencies..."
apt update && apt install -y $app_prereq

# Determine download URL based on architecture
ARCH=$(dpkg --print-architecture)
dlbase="https://services.sonarr.tv/v1/download/main/latest?version=4&os=linux"
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

# Remove previous tarball if present
echo "Cleaning up old files..."
rm -f "Sonarr.*.tar.gz"

# Download the Sonarr tarball
echo "Downloading Sonarr..."
wget --content-disposition "$DLURL"

# Extract Sonarr files
echo "Extracting Sonarr files..."
tar -xvzf "Sonarr.*.tar.gz" --strip-components=1 -C "$installdir"
rm -f "Sonarr.*.tar.gz"

# Apply correct permissions
echo "Setting permissions for $installdir..."
chmod -R 775 "$installdir"
chown -R sonarr:media "$installdir"

# Ensure the data directory exists
echo "Ensuring data directory exists..."
mkdir -p "$datadir"

echo "Installation complete. Sonarr is ready to start via Pterodactyl."
exit 0
