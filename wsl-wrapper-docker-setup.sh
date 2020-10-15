#!/bin/bash

# Script to do initial setup on remote host(s), including Docker installation/configuration
# Intent is for this to be ran from a WSL terminal
# Assumes id_rsa.pub is in the default Windows location & docker script is in C:\dev\scripts
# Author: Gregory Trout 

prompt_usernames() {
  read -p "Enter local Windows username: "  winUser
  read -p "Enter remote Linux username: "  linUser
}

prompt_linux_hostname() {
  read -p "Enter remote Linux hostname: "  remhost
}

copy_key_setup_docker() {
  cat /mnt/c/Users/$winUser/.ssh/id_rsa.pub | ssh $linUser@$remhost "cat >> ~/.ssh/authorized_keys"
  scp /mnt/c/Users/$winUser/scripts/docker-setup.sh $linUser@$remhost:~/docker-setup.sh
  ssh $linUser@$remhost chmod +x /home/$linUser/docker-setup.sh
  ssh $linUser@$remhost /home/$linUser/docker-setup.sh
}

prompt_repeat_setup() {
  read -p "Do again on another Linux host? (y/n) " answer
    if [[ $answer =~ ^[Yy]$ ]]
      then prompt_linux_hostname
	  copy_key_setup_docker
	  prompt_repeat_setup
    else
      exit
    fi
}

prompt_usernames
prompt_linux_hostname
copy_key_setup_docker
prompt_repeat_setup
