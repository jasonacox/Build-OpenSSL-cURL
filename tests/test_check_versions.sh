#!/bin/bash
#
# Offline test for check-versions.sh using saved GitHub API fixtures.
#
# Usage: bash tests/test_check_versions.sh

REPO="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/boc-cv.XXXXXX")" || exit 1
trap 'rm -rf "$WORK"' EXIT
cp "$REPO/check-versions.sh" "$WORK/"
export RELEASES_DIR="$REPO/tests/fixtures"
FAILS=0

# run <openssl> <curl> <nghttp2> <expected rc> <expected text...>
run() {
	local o="$1" c="$2" n="$3" rc_want="$4"; shift 4
	printf 'OPENSSL="%s"\nLIBCURL="%s"\nNGHTTP2="%s"\n' "$o" "$c" "$n" > "$WORK/build.sh"
	local out rc
	out=$(bash "$WORK/check-versions.sh"); rc=$?
	if [ $rc -ne "$rc_want" ]; then
		echo "FAIL: $o/$c/$n exit $rc, expected $rc_want"; echo "$out"; FAILS=$((FAILS+1)); return
	fi
	for want in "$@"; do
		if ! grep -qF -- "$want" <<< "$out"; then
			echo "FAIL: $o/$c/$n missing '$want'"; echo "$out"; FAILS=$((FAILS+1)); return
		fi
	done
	echo "ok:   $o/$c/$n"
}

# outdated: stays on the OpenSSL 3.0 series, ignores curl prerelease
run 3.0.18 8.17.0 1.68.0 1 "-> 3.0.22 available" "-> 8.23.0 available" "-> 1.71.0 available"
# up to date: 3.5 series picks 3.5.9 (not 3.5.10-alpha1, 3.6.x or 4.x)
run 3.5.9 8.23.0 1.71.0 0 "3.5.9      up to date" "8.23.0     up to date" "1.71.0     up to date"
# OpenSSL 3.5.8 -> 3.5.9 even though 3.5.8 is listed after 3.5.9
run 3.5.8 8.23.0 1.71.0 1 "-> 3.5.9 available"

if [ $FAILS -ne 0 ]; then
	echo "$FAILS failure(s)"; exit 1
fi
echo "PASS"
