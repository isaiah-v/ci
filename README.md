# ci
My Personal Continuous Interaction Setup. This project documents the setup process for my personal ci envoirnment. Currently everythiing is installed on a single machine. This should be sufficient for personal use. It could also be a starting point for larger setups.

## Stack
| Operating System      | Reverse Proxy | SSL           | Container | Build Server | Deployment |
|-----------------------|---------------|---------------|-----------|--------------|------------|
| Ubuntu Server - 20.04 | Nginx         | Let's Encrypt | Docker    | Jenkins      | Rundeck    |

## Prerequisite 1: Domain Name
A public domain name needs to be setup with a provider, and it needs to be setup point to your [Public IP Address](https://www.whatismyip.com/what-is-my-public-ip-address/). Your provider will have documentation on mapping your domain name.

## Prerequisite 2: Install Ubuntu Server
The install script in this project has only been tested with [Ubuntu Server v20.04 (LTS)](https://ubuntu.com/server).

## Prerequisite 3: Network Setup
Setup your network so that when request come in they are forwaded to your server.

*Configuration:*
 * _DHCP Reservation_: Reserve an IP address for your server. This will prevent your private IP from changeing.
 * _Port Forwarding_: Forward port 80 and 443 to your server. This will expose your server to the internet.

_Warning:_ Do not publicly expose any port other than 80 and 443.

## Install Services

```
git clone https://github.com/isaiah-v/ci.git
cd ci
chmod +x ./install.sh
./install.sh
```

## Public Locations

 * _Jenkins_: `https://$DOMAIN_NAME/jenkins`
 * _Rundeck_: `https://$DOMAIN_NAME/rundeck`
 * _Docker Registry UI_: `https://$DOMAIN_NAME/docker`
