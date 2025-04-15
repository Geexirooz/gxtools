#!/bin/bash

DNS1='1.1.1.1'
DNS2='8.8.8.8'
DNSMASQ_CONFIG='/etc/dnsmasq.d/recon.conf'

restart_dnsmasq(){
sudo /bin/systemctl restart dnsmasq; sleep 1 # Wait 1 secs for the service to load
}

if [ -z "$1" ]; then
    echo "Usage: $0 <IP> [domain]"
    echo "Usage: $0 reset"
    exit 1
fi

# Reset dns servers
if [[ "$1" == "reset" ]]; then
    echo -e "server=$DNS1\nserver=$DNS2" > $DNSMASQ_CONFIG &&
    restart_dnsmasq &&
    echo "DNS servers reset was successful."
    exit 0
fi

# Setup fake resolution
if [ -n "$2" ]; then
    DOMAIN="$2"
else
    DOMAIN=$DOM
fi

IP=$1
RANDOM_STR=$(openssl rand -hex 16)

echo "address=/$DOMAIN/$IP" > $DNSMASQ_CONFIG
restart_dnsmasq

_RESOLVED_IP=$(dig +short "$RANDOM_STR.$DOMAIN")
count=$(echo "$_RESOLVED_IP" | wc -l)

if [[ "$count" -ne 1 ]]; then
    echo "Error: dnsmasq failed"
    exit 1
fi

if [[ "$_RESOLVED_IP" == "$IP" ]]; then
    echo "Success: dnsmasq is configured"
fi

