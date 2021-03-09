# ci
My Personal Continuous Interaction Setup. This project documents the setup process for my personal ci envoirnment.

## Stack
| Operating System      | Reverse Proxy | SSL           | Build Server | Container |
|-----------------------|---------------|---------------|--------------|-----------|
| Ubuntu Server - 20.04 | Nginx         | Let's Encrypt | Jenkins      | Docker    |

## Install
After installing Ubuntu Server v20.04, run the following:
```
git clone https://github.com/isaiah-v/ci.git
cd ci
chmod +x ./install.sh
./install.sh
```
