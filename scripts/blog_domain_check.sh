#!/usr/bin/env bash
#
# ghost.sh: preview the domain and SSL decision that provisioning would make.
#
#     ./blog_domain_check.sh [domain]
#
# Mirrors 02_ghost-config-setup.sh in cloud-init/cloud-config.yaml. Run it from
# the server to check a domain before deploying, or anywhere to see what the
# fallback would look like.
#
# Cases worth trying:
#   ./blog_domain_check.sh                     # no domain -> nip.io fallback
#   ./blog_domain_check.sh go.ayewo            # non-existent TLD
#   ./blog_domain_check.sh guide.ayewo.com     # round-robin, several A records
#
set -uo pipefail

ghost_blog_domain=${1:-}
ghost_ssl_force=${ghost_ssl_force:-false}

# The address the internet sees us as. A floating address is delivered by NAT on
# both clouds, so it never shows up on a local interface.
instance_public_ip=""
for url in https://checkip.amazonaws.com https://api.ipify.org https://ifconfig.me/ip; do
    reply=$(curl -fsS --max-time 10 "$url" 2>/dev/null) || continue
    reply=$(printf '%s' "$reply" | grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}' | head -1)
    if [[ -n "$reply" ]]; then
        instance_public_ip=$reply
        break
    fi
done
[[ -n "$instance_public_ip" ]] || { echo "Could not determine this host's public IP." >&2; exit 1; }

convertIP2domain() {
    # This will convert  19.70.1.1 to ghost-sh-19-70-1-1.nip.io.
    local domain=$(echo "$1" | sed 's/\./-/g')

    # Add the prefix and suffix to the domain
    domain="ghost-sh-$domain.nip.io"

    echo "$domain"
}

# True when one of the domain's A records is this server. Testing for membership
# rather than equality is what lets a round-robin domain resolve correctly.
domain_points_here() {
    getent ahostsv4 "$1" 2>/dev/null | awk '{print $1}' | grep -qxF "$2"
}

resolved=""
using_fallback_domain=0

if [[ -n "$ghost_blog_domain" ]]; then
    resolved=$(getent ahostsv4 "$ghost_blog_domain" 2>/dev/null | awk '{print $1}' | sort -u | paste -sd' ' -)

    if domain_points_here "$ghost_blog_domain" "$instance_public_ip"; then
        echo "The DNS A-record for domain $ghost_blog_domain correctly resolves to the IP of this server: $instance_public_ip."
    else
        echo "The DNS A-record for domain $ghost_blog_domain does not resolve to the IP of this server: $instance_public_ip."
        echo "Will use nip.io to 'create' a domain based on the server's public IP: $instance_public_ip."
        ghost_blog_domain=$(convertIP2domain "$instance_public_ip")
        using_fallback_domain=1
    fi
else
    echo "No domain was specified. Will use nip.io to 'create' a domain based on the server's public IP: $instance_public_ip."
    ghost_blog_domain=$(convertIP2domain "$instance_public_ip")
    using_fallback_domain=1
fi

# Let's Encrypt counts its rate limits per registered domain, and nip.io is
# absent from the Public Suffix List, so every nip.io user shares one quota.
ghost_ssl_mode=none
if [[ "$using_fallback_domain" -eq 0 ]]; then
    ghost_ssl_mode=letsencrypt
elif [[ "$ghost_ssl_force" == "true" ]]; then
    ghost_ssl_mode=letsencrypt
fi

if [[ "$ghost_ssl_mode" == "none" ]]; then
    ghost_blog_url="http://$ghost_blog_domain"
else
    ghost_blog_url="https://$ghost_blog_domain"
fi

echo
echo "Domain:              $ghost_blog_domain"
echo "Domain IP Address:   ${resolved:-(none)}"
echo "Instance IP Address: $instance_public_ip"
echo "Blog URL:            $ghost_blog_url"
echo "SSL:                 $ghost_ssl_mode"
