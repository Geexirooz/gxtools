#!/bin/bash

# Function to print usage/help message
usage() {
    echo "Usage: $0 <fqdn-name>"
    exit 1
}

# Check if exactly two parameters are provided
if [ "$#" -ne 1 ]; then
    echo "Error: Exactly one parameter required."
    usage
fi

domain=$1

while true; do
    cname=$(/usr/bin/dig +short CNAME $domain)
    if [ -z "$cname" ]; then
	echo $domain
	break
    else
        domain=$cname
    fi
done

