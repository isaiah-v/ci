#!/bin/bash

PRIVATE_IP=$(hostname -I | awk '{print $1}')

echo PRIVATE_IP = $PRIVATE_IP

# --== Nginx ==-- #
sudo docker rm -f ci-nginx

# --== Rundeck ==-- #
sudo docker rm -f ci-rundeck

# --== Jenkins ==-- #
sudo docker rm -f ci-jenkins

# --== Docker Registry UI ==-- #
sudo docker rm -f ci-registry-ui

# --== Docker Registry ==-- #
sudo docker rm -f ci-registry

# -== Remove Insecure Communication for CI registry ==-- #
if test -f "/etc/docker/daemon.json"; then

    if ! [ -x "$(command -v jq)" ]; then
        sudo apt-get -y install jq || exit 1
    fi;

    sudo cp /etc/docker/daemon.json /etc/docker/daemon.json~
    sudo cat /etc/docker/daemon.json | jq "if (.\"insecure-registries\" != null) and (.\"insecure-registries\" | index([\"$PRIVATE_IP:5000\"])) then .\"insecure-registries\"-=[\"$PRIVATE_IP:5000\"] else . end" > /etc/docker/daemon.json
fi;
sudo systemctl restart docker