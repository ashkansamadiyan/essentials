#!/bin/bash

# Step 0: Install 'expect' if not already installed
echo "Installing 'expect' to handle ExpressVPN activation..."
sudo apt-get update
sudo apt-get install -y expect

# Step 1: Install ExpressVPN
echo "Installing ExpressVPN..."
sudo dpkg -i expressvpn_3.70.0.2-1_amd64.deb

# Check for installation issues
if [ $? -ne 0 ]; then
    echo "ExpressVPN installation failed. Attempting to fix broken dependencies..."
    sudo apt-get install -f -y
fi

# Step 2: Use expect to activate ExpressVPN
echo "Activating ExpressVPN using provided activation code..."
expect <<EOF
spawn expressvpn activate
expect "Enter activation code:"
send "E8JVUF99EVNKEXT2ZM7R955\r"
expect eof
EOF

# Step 3: Connect to the US DE server using ExpressVPN
echo "Connecting to US DE server using ExpressVPN..."
expressvpn connect usde

# Step 4: Remove existing Docker-related packages
echo "Removing any pre-existing Docker packages..."
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do 
    sudo apt-get remove -y $pkg 
done

# Step 5: Update the system and install required dependencies for Docker
echo "Updating system and installing dependencies..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl

# Step 6: Add Docker’s official GPG key
echo "Adding Docker's official GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Step 7: Add Docker’s repository to Apt sources
echo "Adding Docker's repository to Apt sources..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Step 8: Update the package list again
echo "Updating package list..."
sudo apt-get update

# Step 9: Install Docker and its components
echo "Installing Docker..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Step 10: Configure Docker to use the Iran server mirror
echo "Configuring Docker to use Iran server mirror..."
sudo mkdir -p /etc/docker
echo '{
  "registry-mirrors": ["https://docker.iranserver.com"]
}' | sudo tee /etc/docker/daemon.json > /dev/null

# Step 11: Reload the systemd daemon and restart Docker
echo "Reloading systemd and restarting Docker..."
sudo systemctl daemon-reload
sudo systemctl restart docker

echo "Setup complete. ExpressVPN is connected and Docker is installed and configured."
