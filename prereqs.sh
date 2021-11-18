#!/bin/bash

set -e -u -o pipefail

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# General update for the system
sudo apt-get -qy update -y && sudo apt-get -qy upgrade

## Install Docker engine
# Commands from https://docs.docker.com/engine/install/ubuntu/
sudo apt-get -qy install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    docker-ce docker-ce-cli containerd.io 

sudo groupadd docker -f
sudo usermod -aG docker $USER

## Install KIND
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.11.1/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

## kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

## k9s for the ease of setup
curl -Lo k9s.tgz https://github.com/derailed/k9s/releases/download/v0.25.3/k9s_Linux_x86_64.tar.gz
tar -zxf k9s.tgz
sudo mv ./k9s /usr/local/bin/k9s

## Start network
git clone https://github.com/hyperledger/fabric-samples.git


LOCALIP=$(hostname -I | cut -f 1 -d' ' | tr . -)

cat << EOF > cfg.env
CLUSTER_TYPE=iks
CONSOLE_DOMAIN=${LOCALIP}.nip.io

CONSOLE_STORAGE_CLASS=standard
DOCKER_EMAIL=<your email here>
DOCKER_PW=<entitlement key>
EOF
echo =====================
echo Please edit the cfg.env file
cat cfg.env

cd fabric-samples/test-network-k8s
./network kind
