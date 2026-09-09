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

# Sizes come out of du and df in KB. Round MB upwards and keep a decimal on GB,
# so a small archive reports "1 MB" rather than a useless "0 MB".
human_kb() {
    local kb=$1
    if (( kb < 1024 )); then
        printf '%d KB' "$kb"
    elif (( kb < 1048576 )); then
        printf '%d MB' $(( (kb + 1023) / 1024 ))
    else
        printf '%d.%d GB' $(( kb / 1048576 )) $(( (kb % 1048576) * 10 / 1048576 ))
    fi
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
[[ -n "$source_version" ]] && echo "Archive came from Ghost $source_version"

# Ghost refuses to move more than two majors at once and wants the latest minor
# of the current major first, so a distant archive needs stepping up before its
# schema will be accepted. Same major is always fine.
if [[ -n "$source_version" ]]; then
    src_major=${source_version%%.*}
    dst_major=${version%%.*}
    if (( src_major != dst_major )); then
        echo
        echo "Note: this archive crosses a major version ($src_major -> $dst_major)."
        echo "If the import is rejected, restore it onto a Ghost $src_major install first,"
        echo "step that up with 'ghost update v$src_major' then 'ghost update', and"
        echo "take a fresh backup from there."
        echo
    fi
fi

if [[ -n "${GHOST_CLI_STAFF_AUTH_TOKEN:-}" && ! "$GHOST_CLI_STAFF_AUTH_TOKEN" =~ ^[0-9a-f]{24}:[0-9a-f]{64}$ ]]; then
    die "GHOST_CLI_STAFF_AUTH_TOKEN is malformed; it must be 24 hex characters, a colon, then 64 hex characters"
fi

# The archive is briefly on disk three times over: the .zip, the unpacked copy,
# and the copy landing in content/. Images barely compress, so the unpacked size
# is close to the archive size -- check before starting rather than running the
# disk dry halfway through a restore.
archive_kb=$(du -k "$archive" | cut -f1)
avail_kb=$(df -Pk "$ghost_dir" | awk 'NR==2 {print $4}')
needed_kb=$(( archive_kb * 5 / 2 ))
if (( avail_kb < needed_kb )); then
    die "not enough free space in $ghost_dir: a $(human_kb "$archive_kb") archive needs about $(human_kb "$needed_kb"), but only $(human_kb "$avail_kb") is available"
fi

# Unpack beside the Ghost install rather than under /tmp. Two reasons, both of
# which bite on a 1 GB server: systemd mounts /tmp as a tmpfs unless the distro
# masks it, so a large archive would be unpacked into RAM; and staying on one
# filesystem makes the copy into content/ a rename-speed operation rather than a
# second full read and write.
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
    sudo cp -a "$workdir/$part/." "$content_dir/$part/"
    restored+=("$part")
done

if (( ${#restored[@]} )); then
    sudo chown -R "$content_owner" "$content_dir"
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
    echo
    echo "Members were NOT imported -- ghost import only handles content."
    echo "Upload this by hand in Ghost Admin, under Members -> (...) -> Import members:"
    echo "  $kept"
fi
