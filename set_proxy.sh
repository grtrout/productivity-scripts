#!/bin/bash
# set_proxy.sh

PROXYHOST="internet.proxy.com"
PROXYPORT="3128"

echo "*** Preparing to configure proxy settings with host $PROXYHOST and port $PROXYPORT ***"

export {HTTP,HTTPS}_PROXY=$PROXYHOST:$PROXYPORT
export {http,https}_proxy=$PROXYHOST:$PROXYPORT
export {no_proxy,NO_PROXY}=localhost
echo "Set environment variables successfully"

sudo sed -i '/Proxy/s/^#*//g' /etc/apt/apt.conf.d/proxy.conf
echo "Set apt's proxy.conf successfully"

git config --global http.proxy http://internet.proxy.com:3128
echo "Set git's http proxy successfully"

#gcloud config set proxy/type http
#gcloud config set proxy/address $PROXYHOST
#gcloud config set proxy/port $PROXYPORT

#echo "Set gcloud's proxy variables successfully"
echo "*** Proxy setting complete ***"