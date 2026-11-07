#!/bin/bash
#
# Compare the default library versions in build.sh with the latest upstream
# releases (curl, nghttp2, and OpenSSL within the same major.minor LTS series).
#
# Usage: ./check-versions.sh        (exit 0 = up to date, 1 = update available)
#
# Set RELEASES_DIR to a directory of saved GitHub API responses (curl.json,
# nghttp2.json, openssl.json) to run offline (used by tests).

cd "$(dirname "$0")" || exit 2

# Defaults from build.sh
OPENSSL=$(grep -oE '^OPENSSL="[^"]+"' build.sh | sed 's/^OPENSSL="\(.*\)"/\1/')
LIBCURL=$(grep -oE '^LIBCURL="[^"]+"' build.sh | sed 's/^LIBCURL="\(.*\)"/\1/')
NGHTTP2=$(grep -oE '^NGHTTP2="[^"]+"' build.sh | sed 's/^NGHTTP2="\(.*\)"/\1/')

# Fetch the list of releases for a GitHub repo (or read a saved copy)
releases() {
	if [ -n "$RELEASES_DIR" ]; then
		cat "$RELEASES_DIR/$2.json"
	else
		curl -fsSL "https://api.github.com/repos/$1/releases?per_page=100"
	fi
}

# Print the tag names of non-prerelease releases, newest first
tags() {
	grep -oE '"(tag_name|prerelease)": *("[^"]*"|true|false)' \
		| sed -E 's/^"([a-z_]+)": *"?([^"]*)"?$/\1:\2/' \
		| paste -d' ' - - | grep ' prerelease:false$' | sed 's/^tag_name:\([^ ]*\) .*/\1/'
}

LATEST_CURL=$(releases curl/curl curl | tags | sed -n 's/^curl-\([0-9_]*\)$/\1/p' | head -1 | tr '_' '.')
LATEST_NGHTTP2=$(releases nghttp2/nghttp2 nghttp2 | tags | sed -n 's/^v\([0-9.]*\)$/\1/p' | head -1)
SERIES=$(echo "$OPENSSL" | cut -d. -f1-2)
LATEST_OPENSSL=$(releases openssl/openssl openssl | tags | sed -n "s/^openssl-\(${SERIES//./\\.}\.[0-9]*\)$/\1/p" | sort -V | tail -1)

status=0
report() {
	if [ -z "$3" ]; then
		printf "  %-8s %-10s %s\n" "$1" "$2" "(could not determine latest)"
		status=2
	elif [ "$2" == "$3" ]; then
		printf "  %-8s %-10s %s\n" "$1" "$2" "up to date"
	elif [ "$2" == "$(printf '%s\n%s\n' "$2" "$3" | sort -V | tail -1)" ]; then
		printf "  %-8s %-10s %s\n" "$1" "$2" "newer than latest release $3"
	else
		printf "  %-8s %-10s %s\n" "$1" "$2" "-> $3 available"
		[ $status -eq 0 ] && status=1
	fi
}

echo "Default versions in build.sh vs latest upstream releases:"
report "OpenSSL" "$OPENSSL" "$LATEST_OPENSSL"
report "curl" "$LIBCURL" "$LATEST_CURL"
report "nghttp2" "$NGHTTP2" "$LATEST_NGHTTP2"
exit $status
