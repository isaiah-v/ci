#!/bin/bash

read -p "Email: " EMAIL
echo EMAIL = $EMAIL

read -p "Public Host or IP:" HOST
echo HOST = $HOST

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

# --== Docker ==-- #

#Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$DOCKER_ARCH signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get -y install docker-ce docker-ce-cli containerd.io

# Setup Docker Registry
sudo docker run -d -p 5000:5000 --restart=always --name registry registry:2

# Setup Insecure Registry
cp ./Docker/daemon.json ./daemon.json
sed -i "s/<IP>/$PRIVATE_IP/" ./daemon.json
sudo mv ./daemon.json /etc/docker/daemon.json
sudo chown root:root /etc/docker/daemon.json

# Setup Docker Registry UI
sudo docker run --name docker-registry-ui -d -p 5001:80 --restart=always -e URL="https://$HOST" -e REGISTRY_TITLE="$HOST" joxit/docker-registry-ui:static

# Restart Docker
sudo systemctl restart docker

# --== Jenkins ==-- #
sudo docker run -d -u root --restart=always -e JENKINS_OPTS="--prefix=/jenkins" -p 8080:8080 -v /var/run/docker.sock:/var/run/docker.sock -v $(which docker):$(which docker) --name jenkins jenkins/jenkins:jdk11

# --== Nginx ==-- #
sudo docker run -d --restart=always -p 80:80 -p 443:443 --name nginx nginx

# Setup Lets Encrypt SSL
sudo docker exec nginx /bin/sh -c "apt-get update"
sudo docker exec nginx /bin/sh -c "apt-get -y install certbot"
sudo docker exec nginx /bin/sh -c "apt-get -y install python3-certbot-nginx"
sudo docker exec nginx /bin/sh -c "certbot certonly --nginx --non-interactive --agree-tos -m $EMAIL -d $HOST"

# Nginx Congif
cp ./Nginx/nginx.conf ./nginx.conf
sed -i "s/<IP>/$PRIVATE_IP/" ./nginx.conf
sed -i "s/<HOST>/$HOST" ./nginx.conf
sudo docker cp ./nginx.conf nginx:/etc/nginx/nginx.conf
rm ./nginx.conf

# Restart Nginx
sudo docker restart nginx
