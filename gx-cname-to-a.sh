#!/bin/bash

# Function to print usage/help message
usage() {
    echo "Usage: $0 <input-file> <output-file>"
    exit 1
}

# Check if exactly two parameters are provided
if [ "$#" -ne 2 ]; then
    echo "Error: Exactly two parameters required."
    usage
fi

# Define variables
input_file=$1
output_file=$2

# Define commands
ANEW=$HOME/go/bin/anew

# Check if file exists
if [ ! -f "$input_file" ]; then
    echo "Error: File not found."
    exit 1
fi

while IFS= read -r domain; do
    # Ignore empty lines or lines starting with #
    if [ -z "$domain" ] || [[ "$domain" =~ ^# ]]; then
        continue
    fi

    # Follow CNAME chain until final domain is found
    while true; do
        cname=$(/usr/bin/dig +short CNAME $domain)
        if [ -z "$cname" ]; then
            # No CNAME, resolve the final domain to A record
            # a_record=$(/usr/bin/dig +short A $domain)
            echo "$domain" | $ANEW -q $output_file
            break
        else
            # Follow the CNAME
            domain=$cname
        fi
    done
done < "$input_file"
