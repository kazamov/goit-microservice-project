#!/usr/bin/bash

set -e

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Update package list
apt-get update

# Install Python 3 and pip
if command_exists python3; then
    echo "Python3 is already installed."
else
    echo "Installing Python3..."
    export DEBIAN_FRONTEND=noninteractive && \
    apt install -y tzdata && \
    ln -fs /usr/share/zoneinfo/Etc/UTC /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata && \
    apt install -y python3 python3-pip
fi

# Install Docker (usually not needed inside a container, but included for completeness)
if command_exists docker && command_exists docker compose; then
    echo "Docker and Docker Compose are already installed."
else
    echo "Installing Docker..."
    apt-get install -y ca-certificates curl && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update

    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    docker run hello-world
fi

# Install Django
if python3 -m django --version >/dev/null 2>&1; then
    echo "Django is already installed."
else
    echo "Installing Django..."
    apt install -y python3-django
fi

echo "All requested development tools are installed."
