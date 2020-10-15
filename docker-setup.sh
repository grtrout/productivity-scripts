#!/bin/bash

# Script to configure a new CloudOps RHEL (or CentOS) VM for Docker
# Author: Gregory Trout 

# SET YUM PROXY
sudo tee -a /etc/yum.conf <<EOF
proxy=http://internet.proxy.com:3128
EOF

# CREATE DOCKER YUM REPO
sudo yum update -y
sudo touch /etc/yum.repos.d/docker.repo
sudo tee /etc/yum.repos.d/docker.repo <<EOF
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/7/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF

# INSTALL DOCKER
sudo yum install docker-engine -y

# SET DOCKER DAEMON PROXY
sudo mkdir -p /etc/systemd/system/docker.service.d/ && sudo touch /etc/systemd/system/docker.service.d/http_proxy.conf
sudo tee /etc/systemd/system/docker.service.d/http_proxy.conf <<EOF
[Service]
Environment="HTTP_PROXY=http://internet.proxy.com:3128"
EOF

# SET DOCKER CLI PROXY
mkdir ~/.docker && touch ~/.docker/config-proxy.json
tee ~/.docker/config-proxy.json <<EOF
{
  "proxies":
  {
    "default":
    {
      "httpProxy": "http://internet.proxy.com:3128",
      "httpsProxy": "https://internet.proxy.com:3128"
    }
  }
}
EOF

# START & TEST DOCKER
sudo systemctl daemon-reload
sudo systemctl start docker.service
sudo docker container run hello-world
