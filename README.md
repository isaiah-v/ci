# ci
My Personal Continuous Interaction Setup. This project documents the setup process for my personal ci environment. Currently everything is installed on a single machine. This should be sufficient for personal use. It could also be a starting point for larger setups.

## Stack
| Operating System      | Reverse Proxy | SSL           | Container | Build Server | Deployment |
|-----------------------|---------------|---------------|-----------|--------------|------------|
| Ubuntu Server - 20.04 | Nginx         | Let's Encrypt | Docker    | Jenkins      | Rundeck    |

## Prerequisites

### 1. Domain Name
You'll need a public domain name that points to your [Public IP Address](https://www.whatismyip.com/). This is required to setup a trusted ssl certificate.

### 2. Ubuntu Server
The install script in this project has only been tested with [Ubuntu Server v20.04 (LTS)](https://ubuntu.com/server). For best results, please use the same operating system.

### 3. Network Setup
Setup your network to forward request to your server. Most, if not all, modern routers support these settings.

*Configuration:*
 * _DHCP Reservation_: Reserve an IP address for your server. This will prevent your private IP from changing.
 * _Port Forwarding_: Forward port 80 and 443 to your server. This will expose your server to the internet.

_Private IP:_ `hostname -I | awk '{print $1}'`

_Warning:_ For this server, do not publicly expose any port other than 80 and 443.

## Install Services

```
git clone https://github.com/isaiah-v/ci.git
cd ci
chmod +x ./install.sh
./install.sh
```

After the installation is complete, reset your passwords.

* Jenkins: Jenkins generates an initial admin password. Assuming you're in the project directory, run `./Jenkins/initialAdminPassword.sh`
* Rundeck: admin/admin

## Public Locations

 * _Jenkins_: `https://$DOMAIN_NAME/jenkins`
 * _Rundeck_: `https://$DOMAIN_NAME/rundeck`
 * _Docker Registry UI_: `https://$DOMAIN_NAME/docker`
