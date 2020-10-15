#!/bin/bash
# unset_proxy.sh

echo "*** Preparing to unset/disable proxy settings ***"

unset {HTTP,HTTPS}_PROXY
unset {http,https}_proxy
unset {no_proxy,NO_PROXY}
echo "Unset environment variables successfully"

sudo sed -i '/Proxy/s/^#*/#/g' /etc/apt/apt.conf.d/proxy.conf
echo "Unset apt's proxy.conf successfully"

git config --global --unset http.proxy
echo "Unset git's http proxy successfully"

#gcloud config unset proxy/type
#gcloud config unset proxy/address
#gcloud config unset proxy/port
#echo "Unset gcloud's proxy variables successfully"

echo "*** Proxy unsetting complete ***"