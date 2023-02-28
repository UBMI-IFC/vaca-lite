#! /usr/bin/bash

echo ""

if [ $# -lt 1 ];
then
    echo "A file with the host is required as an argument"
    exit
fi

serverlist=$(cat $1)

for server in ${serverlist}; do 
  ssh-copy-id ${server}
done
