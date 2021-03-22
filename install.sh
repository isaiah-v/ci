#!/bin/bash

read -p "Public Domain Name: " DOMAIN
read -p "Email: " EMAIL
read -p "Admin Username: " ADMIN_USER
read -p "Admin Password: " ADMIN_PASSWORD

PRIVATE_IP=$(hostname -I | awk '{print $1}')

if [ $(arch) == "x86_64" ]; then
   DOCKER_ARCH="amd64"
else
   echo "Error: Unknown Architecture" >&2
   exit 1
fi

echo DOMAIN = $DOMAIN
echo EMAIL = $EMAIL
echo ADMIN_USER = $ADMIN_USER
echo ADMIN_PASSWORD = $ADMIN_PASSWORD
echo PRIVATE_IP = $PRIVATE_IP
echo DOCKER_ARCH = $DOCKER_ARCH

# --== Docker ==-- #
if ! [ -x "$(command -v docker)" ]; then
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

# Allow insecure communication with our internal docker registry
# see https://docs.docker.com/registry/insecure/
if ! [ -x "$(command -v jq)" ]; then
    sudo apt-get -y install jq || exit 1
fi;
if test -f "/etc/docker/daemon.json"; then
    (cat /etc/docker/daemon.json | jq "if (.\"insecure-registries\" != null) and (.\"insecure-registries\" | index([\"$PRIVATE_IP:5000\"])) then . else .\"insecure-registries\"+=[\"$PRIVATE_IP:5000\"] end" > ./daemon.json) || exit 1

    sudo cp /etc/docker/daemon.json /etc/docker/daemon.json~ || exit 1
    sudo mv ./daemon.json /etc/docker/daemon.json || exit 1
    sudo chown root:root /etc/docker/daemon.json || exit 1
else
    (echo "{\"insecure-registries\": [\"$PRIVATE_IP:5000\"]}" | jq '.' > ./daemon.json) || exit 1
    sudo mv ./daemon.json /etc/docker/daemon.json || exit 1
    sudo chown root:root /etc/docker/daemon.json || exit 1
fi
sudo systemctl restart docker

# --== Docker Registry UI ==-- #
sudo docker rm -f ci-registry-ui
sudo docker run --name ci-registry-ui -d -p 5001:80 --restart=always -e URL="https://$DOMAIN" -e REGISTRY_TITLE="$DOMAIN" joxit/docker-registry-ui:static || exit 1

# --== Keycloak ==-- #
sudo docker rm -f ci-keycloak
sudo docker run --name ci-keycloak --restart=always -d -p 8081:8080 -e KEYCLOAK_USER=$ADMIN_USER -e KEYCLOAK_PASSWORD=$ADMIN_PASSWORD quay.io/keycloak/keycloak:12.0.4 || exit 1

# change web context from auth to keycloak/auth
sudo docker exec -w "/opt/jboss/keycloak/standalone/configuration/" ci-keycloak sed -i -e 's/<web-context>auth<\/web-context>/<web-context>keycloak\/auth<\/web-context>/' standalone.xml
sudo docker exec -w "/opt/jboss/keycloak/standalone/configuration/" ci-keycloak sed -i -e 's/<web-context>auth<\/web-context>/<web-context>keycloak\/auth<\/web-context>/' standalone-ha.xml

# restart
sudo docker restart ci-keycloak

# --== Jenkins ==-- #
sudo docker rm -f ci-jenkins
sudo docker run -d -u root --restart=always -e JENKINS_OPTS="--prefix=/jenkins" -p 8080:8080 -p 50000:50000 -v /var/run/docker.sock:/var/run/docker.sock -v $(which docker):$(which docker) --name ci-jenkins jenkins/jenkins:jdk11 || exit 1

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
