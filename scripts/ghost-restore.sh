#!/usr/bin/env bash
#
# ghost.sh: restore a `ghost backup` archive onto a ghost.sh server.
#
# Run this on the server you are migrating TO, as the user that owns the Ghost
# install (ghost-mgr on a ghost.sh server):
#
#     ./ghost-restore.sh backup-from-v6.26.0-on-2026-09-09-12-00-00.zip [ghost-dir]
#
# `ghost import` restores the content and nothing else. It reads its argument as
# JSON and posts it to the Admin API, so it takes the content export from inside
# the archive rather than the archive itself. Images, media, files, themes and
# settings travel in the same archive as ordinary files and are copied into
# content/ here. Members are a CSV that only Ghost Admin can take -- its path is
# printed at the end.
#
# Authentication is the same as for ghost-backup.sh, except the token belongs to
# the blog you are restoring INTO:
#
#     export GHOST_CLI_STAFF_AUTH_TOKEN='<24 hex>:<64 hex>'
#
set -euo pipefail

archive=${1:-}
ghost_dir=${2:-/var/www/ghost}

die() {
    echo "ghost-restore: $*" >&2
    exit 1
}

# Sizes come out of du, df and unzip in KB.
human_kb() {
    numfmt --to=iec --from-unit=1024 --suffix=B "$1"
}

[[ -n "$archive" ]] || die "usage: $0 <backup-archive.zip> [ghost-dir]"
[[ -f "$archive" ]] || die "no such archive: $archive"
[[ -d "$ghost_dir" ]] || die "no Ghost install at $ghost_dir"
command -v ghost >/dev/null 2>&1 || die "ghost-cli is not on PATH"
command -v unzip >/dev/null 2>&1 || die "unzip is not installed (apt-get install unzip)"

archive=$(readlink -f "$archive")
content_dir="$ghost_dir/content"
[[ -d "$content_dir" ]] || die "no content directory at $content_dir"

cd "$ghost_dir"
version=$(ghost version --json 2>/dev/null | grep -oE '"ghostVersion" *: *"[^"]*"' | sed -E 's/.*: *"(.*)"/\1/') || true
[[ -n "$version" ]] || die "no Ghost instance in $ghost_dir"

# from-v<version>-on-... is how `ghost backup` names its output.
source_version=$(basename "$archive" | sed -nE 's/^backup-from-v([0-9]+\.[0-9]+\.[0-9]+)-on-.*/\1/p') || true

echo "Restoring into Ghost $version at $ghost_dir"

# Ghost refuses to move more than two majors at once and wants the latest minor
# of the current major first, so a distant archive needs stepping up before its
# schema will be accepted. Same major is always fine.
if [[ -n "$source_version" ]]; then
    echo "Archive came from Ghost $source_version"
    if (( ${source_version%%.*} != ${version%%.*} )); then
        echo
        echo "Note: this archive crosses a major version (${source_version%%.*} -> ${version%%.*})."
        echo "If the import is rejected, restore it onto a Ghost ${source_version%%.*} install first,"
        echo "step that up with 'ghost update v${source_version%%.*}' then 'ghost update', and"
        echo "take a fresh backup from there."
        echo
    fi
fi

if [[ -n "${GHOST_CLI_STAFF_AUTH_TOKEN:-}" && ! "$GHOST_CLI_STAFF_AUTH_TOKEN" =~ ^[0-9a-f]{24}:[0-9a-f]{64}$ ]]; then
    die "GHOST_CLI_STAFF_AUTH_TOKEN is malformed; it must be 24 hex characters, a colon, then 64 hex characters"
fi

# Room for the unpacked copy, plus a little slack. The content is hard-linked
# into content/ rather than copied, so it is not paid for twice. Ask the archive
# what it actually holds rather than assuming a compression ratio -- images
# barely compress, themes and JSON do.
archive_kb=$(du -k "$archive" | cut -f1)
unpacked_kb=$(( $(unzip -Zt "$archive" | awk '{print $3}') / 1024 ))
avail_kb=$(df -Pk "$ghost_dir" | awk 'NR==2 {print $4}')
needed_kb=$(( unpacked_kb + unpacked_kb / 10 ))
if (( avail_kb < needed_kb )); then
    die "not enough free space in $ghost_dir: unpacking a $(human_kb "$archive_kb") archive needs about $(human_kb "$needed_kb"), but only $(human_kb "$avail_kb") is available"
fi

# Unpack beside the Ghost install rather than under /tmp. Two reasons, both of
# which bite on a 1 GB server: systemd mounts /tmp as a tmpfs unless the distro
# masks it, so a large archive would be unpacked into RAM; and being on the same
# filesystem as content/ is what lets the restore hard-link instead of copy.
workdir=$(mktemp -d -p "$ghost_dir" .ghost.sh-restore.XXXXXX) || die "cannot create a working directory in $ghost_dir"
trap 'rm -rf "$workdir"' EXIT

unzip -q "$archive" -d "$workdir"

# -print -quit rather than a pipe to head: under pipefail a missing data/
# directory would abort the script here instead of reaching the message below.
content_export=$(find "$workdir/data" -maxdepth 1 -name 'content-*.json' -print -quit 2>/dev/null || true)
[[ -n "$content_export" ]] || die "archive has no data/content-*.json; is it really a 'ghost backup' archive?"

members_export=$(find "$workdir/data" -maxdepth 1 -name 'members-*.csv' -print -quit 2>/dev/null || true)

# Restore the files first. Doing it before the import means the posts have their
# images the moment they land, rather than rendering broken for a few seconds.
# stat the existing directory rather than assuming ghost:ghost, so this keeps
# working if the install uses a different owner.
content_owner=$(stat -c '%U:%G' "$content_dir")
restored=()
for part in images media files settings themes; do
    [[ -d "$workdir/$part" ]] || continue
    # -l hard-links rather than copies. The workdir is on the same filesystem by
    # construction, so the unpacked bytes become the content bytes with no second
    # write, and the trap below just drops the extra links. A 2 GB media library
    # stops costing 2 GB of writes and 2 GB of free space.
    sudo cp -al "$workdir/$part/." "$content_dir/$part/"
    restored+=("$part")
done

if (( ${#restored[@]} )); then
    # Only what was restored, rather than walking the whole content tree.
    sudo chown -R "$content_owner" "${restored[@]/#/$content_dir/}"
    echo "Restored into content/: ${restored[*]}"
else
    echo "Archive carried no images, media, files, settings or themes."
fi

echo "Importing content from $(basename "$content_export")"
ghost import "$content_export"

ghost restart

echo
echo "Done. Ghost $version restarted."
if [[ -n "$members_export" ]]; then
    # `ghost import` posts to the content importer, which has no idea what to do
    # with a members CSV. Ghost Admin is the only thing that takes one.
    kept="$ghost_dir/$(basename "$members_export")"
    sudo cp -a "$members_export" "$kept"
    sudo chown "$content_owner" "$kept"
    # Subscriber email addresses and payment identifiers, which nothing else in
    # this flow reads -- keep it to its owner, and say to remove it when done.
    sudo chmod 0600 "$kept"
    echo
    echo "Members were NOT imported -- ghost import only handles content."
    echo "Upload this by hand in Ghost Admin, under Members -> (...) -> Import members:"
    echo "  $kept"
    echo "It holds subscriber emails and payment identifiers, so delete it afterwards."
fi
