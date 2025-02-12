#!/bin/bash
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

