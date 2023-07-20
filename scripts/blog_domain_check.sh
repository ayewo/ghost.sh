#!/bin/bash

instance_public_ip=$(curl -s http://checkip.amazonaws.com)
ghost_blog_domain="$1"
ghost_blog_ip=""

 
# test non-existent tld e.g. go.ayewo
# test round-robin domain e.g. guide.ayewo.com
# set -x

function convertIP2domain() {
    # This will convert  19.70.1.1 to ghost-sh-19-70-1-1.nip.io.
    local domain=$(echo "$1" | sed 's/\./-/g')

    # Add the prefix and suffix to the domain
    domain="ghost-sh-$domain.nip.io"

    echo "$domain"
}


# Check if the a valid domain was specified
if [[ -n "$ghost_blog_domain" ]]; then

    # Run nslookup and store the output in a variable
    output=$(nslookup $ghost_blog_domain | sed -n '3,6p')

    # Extract the IP address using grep and awk
    ghost_blog_ip=$(echo "$output" | grep "Address:" | awk '{print $2}')

    
    if [[ "$ghost_blog_ip" = "$instance_public_ip" ]]; then
        echo "The DNS A-record for domain $ghost_blog_domain correctly resolves to the IP of this server: $instance_public_ip."
    else
        echo "The DNS A-record for domain $ghost_blog_domain does not resolve to the IP of this server: $instance_public_ip."
        echo "Will use nip.io to 'create' a domain based on the server's public IP: $instance_public_ip."
        ghost_blog_domain=$(convertIP2domain $instance_public_ip)
    fi

else
    echo "No domain was specified. Will use nip.io to 'create' a domain based on the server's public IP: $instance_public_ip."
    ghost_blog_domain=$(convertIP2domain $instance_public_ip)
fi


echo "Domain: $ghost_blog_domain"
echo "Domain IP Address: $ghost_blog_ip"
echo "Instance IP Address: $instance_public_ip"

