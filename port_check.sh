#!/bin/bash
# port_check.sh

if [ $# == 0 ]
then
  printf "To check a specific port, provide IP and port (or just a port to default IP to 127.0.0.1)\n\n"
  ss -tulwn
fi

if [ $# == 1 ]
then
  printf "Checking if 127.0.0.1:$1 is in use or free...\n"
  nc -z "127.0.0.1" "$1" && printf "IN USE\n" || printf "FREE\n"
fi

if [ $# == 2 ]
then
  printf "Checking if $1:$2 is in use or free...\n"
  nc -z "$1" "$2" && printf "IN USE\n" || printf "FREE\n"
fi

