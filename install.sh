#!/bin/bash

if [ $(arch) == "x86_64" ];
then
   DOCKER_ARCH = "amd64"
else
   echo "Error: Unknown Architecture" >&2
   exit 1
fi

# Install Depdencies
sudo apt-get update
sudo apt-get -y install apt-transport-https ca-certificates curl gnupg

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$DOCKER_ARCH signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get install docker-ce docker-ce-cli containerd.io
