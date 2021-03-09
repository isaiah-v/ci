# ci
My Personal Continuous Interaction Setup. This project documents the setup process for my personal ci envoirnment. Currently everythiing is installed on a single machine. This should be sufficient for personal use. It could also be a starting point for larger setups.

## Stack
| Operating System      | Reverse Proxy | SSL           | Build Server | Container |
|-----------------------|---------------|---------------|--------------|-----------|
| Ubuntu Server - 20.04 | Nginx         | Let's Encrypt | Jenkins      | Docker    |

## Install
After installing [Ubuntu Server](https://ubuntu.com/server) v20.04, run the following:
```
git clone https://github.com/isaiah-v/ci.git
cd ci
chmod +x ./install.sh
./install.sh
```
