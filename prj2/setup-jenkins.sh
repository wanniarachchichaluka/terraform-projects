#!/bin/bash

EC2_IP=$(terraform output -raw jenkins_public_ip)
SSH_KEY="ansible-test-key-pair-rsa.pem"

waiting_for_ssh(){
    echo "Waiting for SSH to become available..."
    for i in {1..30}; do
        if ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=5 ubuntu@$EC2_IP exit 2>/dev/null; then
            echo "SSH is ready!"
            return 0
        fi
        echo "Attempt $i/30, SSH is not ready yet..."
        sleep 5
    done
    echo "SSH never became available"
    exit 1
}

waiting_for_ssh

ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no ubuntu@$EC2_IP << 'ENDSSH'
#!/bin/bash
set -euxo pipefail

echo "....Starting the remote setup...."

# ================================
# CLEAN OLD JENKINS CONFIG
# ================================
echo "Cleaning old Jenkins repo and keys..."
sudo rm -f /etc/apt/sources.list.d/jenkins.list
sudo rm -f /usr/share/keyrings/jenkins-keyring.*
sudo apt clean

# ================================
# INSTALL BASE PACKAGES
# ================================
sudo apt update
sudo apt install openjdk-17-jdk git curl gnupg ca-certificates -y

# ================================
# INSTALL DOCKER
# ================================
echo "Installing Docker..."
sudo install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
sudo gpg --dearmor --batch --yes -o /etc/apt/keyrings/docker.gpg

sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
| sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

sudo systemctl enable docker
sudo systemctl start docker

# ================================
# 🔥 INSTALL JENKINS (REAL FIX)
# ================================
echo "Installing Jenkins..."

# Import EXACT required key (fixes NO_PUBKEY error)
sudo gpg --keyserver keyserver.ubuntu.com --recv-keys 7198F4B714ABFC68
sudo gpg --export 7198F4B714ABFC68 | sudo tee /usr/share/keyrings/jenkins-keyring.gpg > /dev/null

# Add repo
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] https://pkg.jenkins.io/debian-stable binary/" \
| sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# Install Jenkins
sudo apt update
sudo apt install jenkins -y

# Add Jenkins to Docker group
sudo usermod -aG docker jenkins

# ================================
# INSTALL PYTHON
# ================================
sudo apt install python3 python3-pip python3-venv -y

# ================================
# START SERVICES
# ================================
sudo systemctl restart docker
sudo systemctl restart jenkins

sleep 30

# ================================
# OUTPUT
# ================================
echo "=== INSTALLATION COMPLETE ==="
echo "Jenkins Initial Admin Password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword || echo "Not ready yet"

echo "Jenkins URL: http://$(curl -s http://checkip.amazonaws.com):8080"

sudo systemctl is-active docker && echo "Docker: Running"
sudo systemctl is-active jenkins && echo "Jenkins: Running"

ENDSSH

echo "=== Setup Complete ==="
echo "Jenkins URL: http://${EC2_IP}:8080"
