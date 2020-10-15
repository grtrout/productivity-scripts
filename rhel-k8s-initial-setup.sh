#!/bin/bash
# rhel-k8s-initial-setup.sh

# Script to configure RHEL servers for Docker, Kubernetes, etc.
# This is intended for dev/test purposes only
# Author: Greg Trout

# CONFIRM ROOT ACCOUNT
if ! [ $(id -u) = 0 ]; then
  echo "##### Script must be run with root privileges"
  exit 1
fi

set -u # This prevents running the script if any of the variables have not been set
set -e # Exit if error is detected during pipeline execution

# SET VARIABLES
NONROOT_USER_DEFAULT="user"
NONROOT_USER_PW_DEFAULT="changeme"
NEW_HOSTNAME_DEFAULT="host6"
REMOTE_HOST_DEFAULT="1.2.3.4"

PROXY_HOST="internet.proxy.com"
PROXY_PORT="3128"
KUBECTL_RELEASE_URL="https://storage.googleapis.com/kubernetes-release/release"
DOCKER_YUM_REPO="https://download.docker.com/linux/centos/docker-ce.repo"

# GET USER VALUES OR USE DEFAULTS (AS DEFINED ABOVE)
read -p "Enter non-root user's name [$NONROOT_USER_DEFAULT]: " NONROOT_USER
NONROOT_USER="${NONROOT_USER:-$NONROOT_USER_DEFAULT}"

read -p "Enter non-root user's password [$NONROOT_USER_PW_DEFAULT]: " NONROOT_USER_PW
NONROOT_USER_PW="${NONROOT_USER_PW:-$NONROOT_USER_PW_DEFAULT}"

read -p "Enter new hostname for this node [$NEW_HOSTNAME_DEFAULT]: " NEW_HOSTNAME
NEW_HOSTNAME="${NEW_HOSTNAME:-$NEW_HOSTNAME_DEFAULT}"

read -p "Enter address or hostname for remote control-plane node [$REMOTE_HOST_DEFAULT]: " REMOTE_HOST
REMOTE_HOST="${REMOTE_HOST:-$REMOTE_HOST_DEFAULT}"

# ADD NON-ROOT USER
add_non_root_user() {
  useradd $NONROOT_USER || echo "##### User [$NONROOT_USER] already exists."
  echo "$NONROOT_USER:$NONROOT_USER_PW" | chpasswd
  usermod -aG wheel $NONROOT_USER
  echo "##### User [$NONROOT_USER] created/updated; sudo configured"
}

# SET NEW HOSTNAME
set_hostname() {
  hostnamectl set-hostname $NEW_HOSTNAME
  echo "##### Hostname set to [$NEW_HOSTNAME]"
}

# CREATE SSH DIRECTORY; COPY PUBLIC KEYS FROM REMOTE SERVER
set_up_ssh() {
  mkdir -p -m 700 /home/$NONROOT_USER/.ssh
  ssh $NONROOT_USER@$REMOTE_HOST cat /home/$NONROOT_USER/.ssh/id_rsa.pub | tee -a /home/$NONROOT_USER/.ssh/authorized_keys
  chown -R $NONROOT_USER:$NONROOT_USER /home/$NONROOT_USER/.ssh
  chmod 600 /home/$NONROOT_USER/.ssh/authorized_keys
  echo "##### Public SSH key from [$REMOTE_HOST] copied to authorized_keys"
}

# SET PROXY ENV VARIABLES (IF NOT ALREADY DONE)
set_env_proxy() {
  case $(
    grep -Fq "$PROXY_HOST:$PROXY_PORT" /home/$NONROOT_USER/.bash_profile >/dev/null
    echo $?
  ) in
  0) echo "##### Proxy environment variables already set" ;;
  1)
    cat <<EOF >>/home/$NONROOT_USER/.bash_profile
export {HTTP,HTTPS}_PROXY="$PROXY_HOST:$PROXY_PORT"
export {http,https}_proxy="$PROXY_HOST:$PROXY_PORT"
export {no_proxy,NO_PROXY}="localhost,.domain.com"
EOF
    echo "##### Proxy environment variables set"
    chown $NONROOT_USER:$NONROOT_USER /home/$NONROOT_USER/.bash_profile
    ;;
  *) echo "##### Error setting proxy environment variables" ;;
  esac
}

# DOWNLOAD LATEST VERSION OF KUBECTL
install_kubectl() {
  curl -x $PROXY_HOST:$PROXY_PORT -LO $KUBECTL_RELEASE_URL/$(curl -s $KUBECTL_RELEASE_URL/stable.txt)bin/linux/amd64/kubectl
  mv ./kubectl /usr/local/bin/kubectl
  chown $NONROOT_USER:$NONROOT_USER /usr/local/bin/kubectl
  chmod 775 /usr/local/bin/kubectl
  echo "##### Kubectl installed, configured"
}

# COPY KUBECONFIG FROM REMOTE SERVER
copy_kubeconfig() {
  mkdir -p /home/$NONROOT_USER/.kube
  scp -r $NONROOT_USER@$REMOTE_HOST:/home/$NONROOT_USER/.kube/config /home/$NONROOT_USER/.kube/config
  chown -R $NONROOT_USER:$NONROOT_USER /home/$NONROOT_USER/.kube
  chmod 775 /home/$NONROOT_USER/.kube/
  echo "##### Kubeconfig copied from [$REMOTE_HOST]"
}

# SET YUM PROXY
set_yum_proxy() {
  tee -a /etc/yum.conf <<EOF
proxy=http://$PROXY_HOST:$PROXY_PORT
EOF
  echo "##### Yum proxy configured"
}

# ADD DOCKER-CE REPO
install_docker() {
  yum-config-manager --add-repo $DOCKER_YUM_REPO
  echo "##### Docker-CE repo added to yum"
  # UPDATE YUM
  yum update -y
  echo "##### Yum updated"
  # INSTALL DOCKER
  yum install docker-ce -y
  echo "##### Docker-CE installed"
}

set_docker_proxies() {
  # SET DOCKER DAEMON PROXY
  mkdir -p /etc/systemd/system/docker.service.d/ && sudo touch /etc/systemd/system/docker.service.d/http_proxy.conf
  tee /etc/systemd/system/docker.service.d/http_proxy.conf <<EOF
[Service]
Environment="HTTP_PROXY=http://$PROXY_HOST:$PROXY_PORT"
EOF
  echo "##### Docker daemon proxy configured"

  # SET DOCKER CLI PROXY
  mkdir -p /home/$NONROOT_USER/.docker && touch /home/$NONROOT_USER/.docker/config-proxy.json
  tee /home/$NONROOT_USER/.docker/config-proxy.json <<EOF
{
  "proxies":
  {
    "default":
    {
      "httpProxy": "http://$PROXY_HOST:$PROXY_PORT",
      "httpsProxy": "https://$PROXY_HOST:$PROXY_PORT"
    }
  }
}
EOF
  chown -R $NONROOT_USER:$NONROOT_USER /home/$NONROOT_USER/.docker
  echo "##### Docker CLI proxy configured"
}

init_docker() {
  # START DOCKER
  systemctl daemon-reload
  systemctl start docker.service
  echo "##### Docker started (via root)"

  # ADD NON-ROOT USER TO DOCKER GROUP
  usermod -aG docker $NONROOT_USER
  newgrp docker <<EONG
id
EONG
  echo "##### [$NONROOT_USER] added to docker group"
}

test_docker_k8s() {
  # TEST DOCKER & KUBECTL AS NON-ROOT USER
  su $NONROOT_USER -c "docker container run hello-world"
  su $NONROOT_USER -c "docker version"
  echo "##### Docker works"
  su $NONROOT_USER -c "kubectl version"
  echo "##### Kubectl works"
  echo "##### $BASH_SOURCE completed successfully!"
}

#MAIN
add_non_root_user
set_hostname
set_up_ssh
set_env_proxy
#install_kubectl
#copy_kubeconfig
set_yum_proxy
install_docker
set_docker_proxies
init_docker
test_docker_k8s

# Notes:
# - kubectl/kubeconfig isn't actually needed. And if it's desired, it might be better
#   to copy it from the "remote host" anyway since it seems to fail sometimes and
#   eventually there could be client/server version issues.
# - setting environment proxy really isn't necessary
# - if remote host can execute ssh-copy-id, this would be simpler
# - docker-ce repo added beacuse docker-engine is deprecated
