#!/bin/bash
### Description: Sonarr .NET Debian install

scriptversion="1.0.4"
scriptdate="2025-04-05"

set -euo pipefail

echo "Running Sonarr Install Script - Version [$scriptversion] as of [$scriptdate]"

# Am I root? Need root permissions!
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root."
    exit 1
fi

app="sonarr"
app_port="8989"
app_prereq="curl sqlite3 wget"
branch="main"

# Constants
installdir="/opt/sonarr"              # Install Location
datadir="/opt/sonarr/data"            # AppData directory
app_bin=${app^}                # Binary Name of the app

# Change directory to install location
echo "Changing directory to $installdir..."
mkdir "$installdir" || {
    echo "I can't create directory $2" >&2
    exit 8
}
cd "$installdir"

# Install prerequisite packages
echo "Installing pre-requisite packages..."
apt update && apt install -y $app_prereq

# Determine download URL
ARCH=$(dpkg --print-architecture)
dlbase="https://services.sonarr.tv/v1/download/$branch/latest?version=4&os=linux"
case "$ARCH" in
"amd64") DLURL="${dlbase}&arch=x64" ;;
"armhf") DLURL="${dlbase}&arch=arm" ;;
"arm64") DLURL="${dlbase}&arch=arm64" ;;
*)
    echo "Arch not supported."
    exit 1
    ;;
esac

# Download and Extract Application Files
echo "Removing previous tarballs..."
#rm -f "${app^}".*.tar.gz
echo "Downloading Sonarr tarball..."
wget --content-disposition "$DLURL"
echo "Extracting Sonarr files..."
tar -xvzf "${app^}".*.tar.gz --strip-components=1 -C /opt/sonarr 
#rm -f "${app^}".*.tar.gz

# Change permissions
echo "Setting permissions..."
chmod -R 775 "$installdir"
chown -R root:root "$installdir"

echo "Installation complete. Sonarr is ready to start manually."

# Start the Application
echo "Starting Sonarr manually..."
"$installdir/$app_bin" -v --nobrowser --data="$datadir"
echo "Application started successfully. You can browse to http://<your-ip>:$app_port for the GUI."

# Exit
exit 0
