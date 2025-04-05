#!/bin/bash
### Description: Sonarr .NET Debian install

scriptversion="1.0.4"
scriptdate="2025-04-05"

set -euo pipefail

echo "Running Sonarr Install Script - Version [$scriptversion] as of [$scriptdate]"

# Am I root?, need root!
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root."
    exit
fi

app="sonarr"
app_port="8989"
app_prereq="curl sqlite3 wget"
app_umask="0002"
branch="main"

# Constants
installdir="/opt"              # {Update me if needed} Install Location
bindir="${installdir}/${app^}" # Full Path to Install Location
datadir="/var/lib/$app/"       # {Update me if needed} AppData directory to use
app_bin=${app^}                # Binary Name of the app

if [ "$installdir" == "$(dirname -- "$( readlink -f -- "$0"; )")" ] || [ "$bindir" == "$(dirname -- "$( readlink -f -- "$0"; )")" ]; then
    echo "You should not run this script from the intended install directory. The script will exit. Please re-run it from another directory"
    exit
fi

# Prompt User
read -r -p "What user should ${app^} run as? (Default: $app): " app_uid < /dev/tty
app_uid=$(echo "$app_uid" | tr -d ' ')
app_uid=${app_uid:-$app}
read -r -p "What group should ${app^} run as? (Default: media): " app_guid < /dev/tty
app_guid=$(echo "$app_guid" | tr -d ' ')
app_guid=${app_guid:-media}

echo "This will install [${app^}] to [$bindir] and use [$datadir] for the AppData Directory"
echo "${app^} will run as the user [$app_uid] and group [$app_guid]. By continuing, you've confirmed that the selected user and group will have READ and WRITE access to your Media Library and Download Client Completed Download directories"
read -n 1 -r -s -p $'Press enter to continue or ctrl+c to exit...\n' < /dev/tty

# Create User / Group as needed
if [ "$app_guid" != "$app_uid" ]; then
    if ! getent group "$app_guid" >/dev/null; then
        groupadd "$app_guid"
    fi
fi
if ! getent passwd "$app_uid" >/dev/null; then
    adduser --system --no-create-home --ingroup "$app_guid" "$app_uid"
    echo "Created and added User [$app_uid] to Group [$app_guid]"
fi
if ! getent group "$app_guid" | grep -qw "$app_uid"; then
    echo "User [$app_uid] did not exist in Group [$app_guid]"
    usermod -a -G "$app_guid" "$app_uid"
    echo "Added User [$app_uid] to Group [$app_guid]"
fi

# Create Appdata Directory
mkdir -p "$datadir"
chown -R "$app_uid":"$app_guid" "$datadir"
chmod 775 "$datadir"
echo "Directories created"

# Install prerequisite packages
echo "Installing pre-requisite Packages"
apt update && apt install -y $app_prereq
ARCH=$(dpkg --print-architecture)

# Determine download URL
dlbase="https://services.sonarr.tv/v1/download/$branch/latest?version=4&os=linux"
case "$ARCH" in
"amd64") DLURL="${dlbase}&arch=x64" ;;
"armhf") DLURL="${dlbase}&arch=arm" ;;
"arm64") DLURL="${dlbase}&arch=arm64" ;;
*)
    echo "Arch not supported"
    exit 1
    ;;
esac

# Download and Extract Application Files
echo "Removing previous tarballs"
rm -f "${app^}".*.tar.gz
echo "Downloading..."
wget --content-disposition "$DLURL"
tar -xvzf "${app^}".*.tar.gz
echo "Installation files downloaded and extracted"

# Remove Existing Installation
echo "Removing existing installation"
rm -rf "$bindir"
echo "Installing..."
mv "${app^}" "$installdir"
chown "$app_uid":"$app_guid" -R "$bindir"
chmod 775 "$bindir"
rm -rf "${app^}.*.tar.gz"
touch "$datadir"/update_required
chown "$app_uid":"$app_guid" "$datadir"/update_required
echo "App Installed"

# Start the Application
echo "Starting $app manually..."
"$bindir/$app_bin" --nobrowser --data="$datadir" &
echo "Application started successfully. You can browse to http://<your-ip>:$app_port for the GUI."

# Exit
exit 0
