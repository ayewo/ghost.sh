#!/usr/bin/env bash
#
# ghost.sh: take a full backup of a Ghost blog, ready to be moved elsewhere.
#
# Run this on the server you are migrating FROM, as the user that owns the Ghost
# install (ghost-mgr on a ghost.sh server):
#
#     ./ghost-backup.sh [ghost-dir]
#
# Ghost 5.129.0 and later authenticate this with a Staff access token rather than
# a password, because Ghost-CLI has no way to answer a two-factor prompt. Create
# one in Ghost Admin under Settings -> Advanced -> Integrations -> Add custom
# integration, then export its Admin API key before running this:
#
#     export GHOST_CLI_STAFF_AUTH_TOKEN='<24 hex>:<64 hex>'
#
set -euo pipefail

ghost_dir=${1:-/var/www/ghost}

die() {
    echo "ghost-backup: $*" >&2
    exit 1
}

[[ -d "$ghost_dir" ]] || die "no Ghost install at $ghost_dir"
command -v ghost >/dev/null 2>&1 || die "ghost-cli is not on PATH"

cd "$ghost_dir"

version=$(ghost version --json 2>/dev/null | grep -oE '"ghostVersion" *: *"[^"]*"' | sed -E 's/.*: *"(.*)"/\1/') || true
[[ -n "$version" ]] || die "no Ghost instance in $ghost_dir"
echo "Backing up Ghost $version at $ghost_dir"

# Ghost-CLI prompts for the token when it is absent, which is fine interactively
# but hangs a scripted run. Say so up front instead.
if [[ -z "${GHOST_CLI_STAFF_AUTH_TOKEN:-}" ]]; then
    echo
    echo "GHOST_CLI_STAFF_AUTH_TOKEN is not set, so Ghost-CLI will prompt for a"
    echo "Staff access token. Export one to run this unattended -- see the notes"
    echo "at the top of this script."
    echo
elif [[ ! "$GHOST_CLI_STAFF_AUTH_TOKEN" =~ ^[0-9a-f]{24}:[0-9a-f]{64}$ ]]; then
    die "GHOST_CLI_STAFF_AUTH_TOKEN is malformed; it must be 24 hex characters, a colon, then 64 hex characters"
fi

# Writes backup-from-v<version>-on-<timestamp>.zip into the working directory.
ghost backup

# || true so that finding nothing reaches the message below rather than
# aborting at this assignment under pipefail.
archive=$(ls -1t "$ghost_dir"/backup-from-v*.zip 2>/dev/null | head -1) || true
[[ -n "$archive" ]] || die "ghost backup reported success but left no archive in $ghost_dir"

echo
echo "Archive: $archive"
echo "Size:    $(du -h "$archive" | cut -f1)"
echo
echo "Contents:"
unzip -Z1 "$archive" | awk -F/ '{print $1}' | sort | uniq -c | sort -rn | sed 's/^/  /' || true
echo
echo "Copy it to the new server and restore it with ghost-restore.sh:"
echo "  scp -i <key> $archive <user>@<new-server>:~/"
