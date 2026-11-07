#!/bin/bash
#
# Static checks for the build scripts:
#  1. shellcheck at warning severity must be clean
#  2. libcurl must link against the same OpenSSL Catalyst directory that the
#     OpenSSL build creates (case matters on case-sensitive volumes)
#
# Usage: bash tests/test_lint.sh

cd "$(dirname "$0")/.." || exit 1
FAILS=0

if command -v shellcheck > /dev/null; then
	if shellcheck -S warning ./*.sh ./*/*.sh; then
		echo "ok:   shellcheck"
	else
		echo "FAIL: shellcheck"; FAILS=$((FAILS+1))
	fi
else
	echo "skip: shellcheck not installed"
fi

# Directory created by OpenSSL phase 1 for Catalyst output
if ! grep -q '^mkdir -p Catalyst/lib' openssl/openssl-build-phase1.sh; then
	echo "FAIL: openssl no longer creates Catalyst/lib"; FAILS=$((FAILS+1))
elif grep -n 'OPENSSL}/catalyst' curl/libcurl-build.sh; then
	echo "FAIL: libcurl uses lowercase openssl/catalyst path"; FAILS=$((FAILS+1))
else
	echo "ok:   catalyst openssl path"
fi

if [ $FAILS -ne 0 ]; then
	echo "$FAILS failure(s)"; exit 1
fi
echo "PASS"
