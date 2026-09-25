#!/usr/bin/env bash
#
# ghost.sh: check whether a domain already points at this server, and show the
# nip.io name that provisioning would fall back to if it does not.
#
#     ./blog_domain_check.sh [domain] [server-address]
#
# Cases worth trying:
#   ./blog_domain_check.sh                     # no domain -> show the fallback
#   ./blog_domain_check.sh go.ayewo            # non-existent TLD
#   ./blog_domain_check.sh guide.ayewo.com     # round-robin, several A records
#
# This deliberately does NOT predict whether a certificate will be issued.
# Provisioning decides that by asking Let's Encrypt and keeping the answer in
# /etc/ghost.sh/install.env; anything here would be a guess that drifts.
#
set -uo pipefail

ghost_blog_domain=${1:-}
server_address=${2:-}

# Without an explicit address, ask what the internet sees this host as. Note this
# is the *egress* address: on a DigitalOcean droplet holding a reserved IP, that
# is the droplet's own address rather than the reserved one, unless the default
# route has been repointed at the anchor gateway. Pass the address as the second
# argument to check against a floating address.
if [[ -z "$server_address" ]]; then
    for url in https://checkip.amazonaws.com https://api.ipify.org https://ifconfig.me/ip; do
        reply=$(curl -fsS --connect-timeout 3 --max-time 5 "$url" 2>/dev/null) || continue
        reply=$(printf '%s' "$reply" | grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}' | head -1)
        if [[ -n "$reply" ]]; then
            server_address=$reply
            break
        fi
    done
fi
[[ -n "$server_address" ]] || { echo "Could not determine this host's public address; pass it as the second argument." >&2; exit 1; }

# 19.70.1.1 -> ghost-sh-19-70-1-1.nip.io, which resolves back to 19.70.1.1.
fallback_domain="ghost-sh-$(echo "$server_address" | sed 's/\./-/g').nip.io"

resolved=""
points_here=no
if [[ -n "$ghost_blog_domain" ]]; then
    # Resolved once, then tested for membership: a round-robin domain has several
    # A records and only one of them needs to be us.
    resolved=$(getent ahostsv4 "$ghost_blog_domain" 2>/dev/null | awk '{print $1}' | sort -u)
    if grep -qxF "$server_address" <<< "$resolved"; then
        points_here=yes
    fi
fi

resolved_flat="(none)"
if [[ -n "$resolved" ]]; then
    resolved_flat=$(echo $resolved | tr '\n' ' ')
fi

if [[ -z "$ghost_blog_domain" ]]; then
    echo "No domain given. Provisioning would use the nip.io fallback."
elif [[ "$points_here" == yes ]]; then
    echo "The DNS A-record for domain $ghost_blog_domain correctly resolves to the IP of this server: $server_address."
else
    echo "The DNS A-record for domain $ghost_blog_domain does not resolve to the IP of this server: $server_address."
    echo "Provisioning would use the nip.io fallback instead."
fi

echo
echo "Server address:    $server_address"
echo "Domain:            ${ghost_blog_domain:-(none given)}"
echo "Domain A-records:  $resolved_flat"
echo "Points at server:  $points_here"
echo "nip.io fallback:   $fallback_domain"
