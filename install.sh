#!/bin/bash

PRIVATE_IP=$(hostname -I | awk '{print $1}')
echo PRIVATE_IP = $PRIVATE_IP

if [ $(arch) == "x86_64" ];
then
   DOCKER_ARCH="amd64"
   echo DOCKER_ARCH = $DOCKER_ARCH
else
   echo "Error: Unknown Architecture" >&2
   exit 1
fi

# Depdencies
sudo apt-get update
sudo apt-get -y install apt-transport-https ca-certificates curl gnupg

# Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$DOCKER_ARCH signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get -y install docker-ce docker-ce-cli containerd.io

# Docker Registry
sudo docker run -d -p 5000:5000 --restart=always --name registry registry:2

# Docker Registry UI
sudo docker run --name docker-registry-ui -d -p 8081:80 --restart=always -e URL=https://ivcode.org -e REGISTRY_TITLE="ivcode.org" joxit/docker-registry-ui:static

# Jenkins
sudo docker run -d --restart=always -e JENKINS_OPTS="--prefix=/jenkins" -p 8080:8080 -v /var/run/docker.sock:/var/run/docker.sock -v $(which docker):$(which docker) --name jenkins jenkins/jenkins

# Nginx
sudo docker run -d --restart=always -p 80:80 -p 443:443 --name nginx nginx
sudo docker exec nginx /bin/sh -c "apt-get update"
sudo docker exec nginx /bin/sh -c "apt-get -y install certbot"
sudo docker exec nginx /bin/sh -c "apt-get -y install python3-certbot-nginx"
sudo docker exec nginx /bin/sh -c "certbot certonly --nginx --non-interactive --agree-tos -m isaiah.v@comcast.net -d ivcode.org"

cp ./Nginx/nginx.conf ./nginx.conf
sed -i "s/<IP>/$PRIVATE_IP/" ./nginx.conf
sudo docker cp ./nginx.conf nginx:/etc/nginx/nginx.conf
rm ./nginx.conf

sudo docker restart nginx
