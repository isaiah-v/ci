# ci
My Personal Continuous Interaction Setup. This project documents the setup process for my personal ci envoirnment.

## Stack
| Operating System      | Reverse Proxy | Build Server | Container |
|-----------------------|---------------|--------------|-----------|
| Ubuntu Server - 20.04 | Nginx         | Jenkins      | Docker    |

## Install
After installing Ubuntu Server v20.04, run the following script.

```
git clone https://github.com/isaiah-v/ci.git
cd ci
chmod +x ./install.sh
./install.sh
```
