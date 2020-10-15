#!/bin/bash
# port_check.sh

if [ $# == 0 ]
then
  echo "Provide IP and port or just a port to default IP to 127.0.0.1"
fi

if [ $# == 1 ]
then
  echo "Checking if port $1 on 127.0.0.1 is in use or free..."
  nc -z "127.0.0.1" "$1" && echo "IN USE" || echo "FREE"
fi

if [ $# == 2 ]
then
  echo "Checking if port $2 on $1 is in use or free..."
  nc -z "$1" "$2" && echo "IN USE" || echo "FREE"
fi

