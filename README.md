# ci
My Personal Continuous Interaction Setup. This project documents the setup process for my personal ci envoirnment. Currently everythiing is installed on a single machine. This should be sufficient for personal use. It could also be a starting point for larger setups.

## Stack
| Operating System      | Reverse Proxy | SSL           | Container | Build Server | Deployment |
|-----------------------|---------------|---------------|-----------|--------------|------------|
| Ubuntu Server - 20.04 | Nginx         | Let's Encrypt | Docker    | Jenkins      | Rundeck    |

## Install
After installing [Ubuntu Server](https://ubuntu.com/server) v20.04, run the following:
```
git clone https://github.com/isaiah-v/ci.git
cd ci
chmod +x ./install.sh
./install.sh
```
## Network Setup
Security is managed by using reverse proxies and controlling what ports are exposed to the internet. The install scripts assume port 80 and 443 are public. No other ports from this machine should be exposed to the internet.

*Configuration:*
 * _DHCP Reservation_: Reserve an IP address for your server. This will prevent your private IP from changeing.
 * _Port Forwarding_: Forward port 80 and 443 to your server. This will expose your server to the internet.

## Services
 * _Jenkins_: `https://$YOUR_HOST/jenkins`
 * _Rundeck_: `https://$YOUR_HOST/rundeck`
 * _Docker Registry UI_: `https://$YOUR_HOST/docker`
