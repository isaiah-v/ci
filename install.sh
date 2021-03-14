#!/bin/bash

read -p "Public Domain Name:" DOMAIN

read -p "Email: " EMAIL


PRIVATE_IP=$(hostname -I | awk '{print $1}')

if [ $(arch) == "x86_64" ];
then
   DOCKER_ARCH="amd64"
else
   echo "Error: Unknown Architecture" >&2
   exit 1
fi

echo DOMAIN = $DOMAIN
echo EMAIL = $EMAIL
echo PRIVATE_IP = $PRIVATE_IP
echo DOCKER_ARCH = $DOCKER_ARCH

# --== Docker ==-- #
if [ -x "$(command -v docker)" ];
then
   # install docker if it's not already installed
   sudo apt-get update || exit 1
   sudo apt-get -y install apt-transport-https ca-certificates curl gnupg || exit 1
   
   (curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg) || exit 1
   (echo "deb [arch=$DOCKER_ARCH signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null) || exit 1
   sudo apt-get update || exit 1
   sudo apt-get -y install docker-ce docker-ce-cli containerd.io || exit 1
fi;


# --== Docker Registry ==-- #
sudo docker rm -f ci-registry
sudo docker run -d -p 5000:5000 --restart=always --name ci-registry registry:2 || exit 1;

# Setup Insecure Registry
cp ./Docker/daemon.json ./daemon.json
sed -i "s/<IP>/$PRIVATE_IP/" ./daemon.json
sudo mv ./daemon.json /etc/docker/daemon.json
sudo chown root:root /etc/docker/daemon.json

# Restart Docker
sudo systemctl restart docker

# --== Docker Registry UI ==-- #
sudo docker rm -f ci-registry-ui
sudo docker run --name ci-registry-ui -d -p 5001:80 --restart=always -e URL="https://$DOMAIN" -e REGISTRY_TITLE="$DOMAIN" joxit/docker-registry-ui:static || exit 1

# --== Jenkins ==-- #
sudo docker rm -f ci-jenkins
sudo docker run -d -u root --restart=always -e JENKINS_OPTS="--prefix=/jenkins" -p 8080:8080 -v /var/run/docker.sock:/var/run/docker.sock -v $(which docker):$(which docker) --name ci-jenkins jenkins/jenkins:jdk11 || exit 1

# --== Rundeck ==-- #
sudo docker rm -f ci-rundeck
sudo docker run -d --restart=always --name ci-rundeck -p 4440:4440 -e RUNDECK_GRAILS_URL="https://$DOMAIN/rundeck" -e RUNDECK_SERVER_CONTEXTPATH="/rundeck" -e RUNDECK_SERVER_FORWARDED=true rundeck/rundeck:3.3.10 || exit 1

# --== Nginx ==-- #
sudo docker rm -f ci-nginx
sudo docker run -d --restart=always -p 80:80 -p 443:443 --name ci-nginx nginx || exit 1

# Setup Lets Encrypt SSL
sudo docker exec ci-nginx /bin/sh -c "apt-get update" || exit 1
sudo docker exec ci-nginx /bin/sh -c "apt-get -y install certbot" || exit 1
sudo docker exec ci-nginx /bin/sh -c "apt-get -y install python3-certbot-nginx" || exit 1
sudo docker exec ci-nginx /bin/sh -c "certbot certonly --nginx --non-interactive --agree-tos -m $EMAIL -d $DOMAIN" || exit 1

# Nginx Congif
cp ./Nginx/nginx.conf ./nginx.conf || exit 1
sed -i "s/<IP>/$PRIVATE_IP/" ./nginx.conf || exit 1
sed -i "s/<DOMAIN>/$DOMAIN/" ./nginx.conf || exit 1
sudo docker cp ./nginx.conf ci-nginx:/etc/nginx/nginx.conf || exit 1
rm ./nginx.conf || exit 1

# Restart Nginx
sudo docker restart ci-nginx || exit 1

# --== Post Install Info ==-- #
echo Please Reset Your Passwords
echo Jenkins Initial Admin Password = $(./Jenkins/initialAdminPassword.sh)
echo Rundeck Default Password = admin/admin
