#!/bin/bash
#
# Regression test: a failed source download (e.g. a mistyped version that
# returns HTTP 404) must stop the build with a clear error and must NOT leave
# a bogus "<pkg>.tar.gz" behind. Otherwise the HTML error page gets cached and
# every later run reports "Using <pkg>.tar.gz" and fails in tar.
#
# Runs offline: a stub `curl` emulates a server returning 404, and /tmp paths in
# a scratch copy of each script are redirected into a private temp dir.
#
# Usage: bash tests/test_download.sh

REPO="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/boc-test.XXXXXX")" || exit 1
trap '[ -n "$KEEP" ] || rm -rf "$WORK"' EXIT
FAILS=0

# Stub curl: honours --fail like the real one (exit 22, no file written);
# without it, writes the HTML error page to the -O filename and "succeeds".
mkdir -p "$WORK/bin"
cat > "$WORK/bin/curl" <<'STUB'
#!/bin/bash
fail=0; out=""
for a in "$@"; do
	case "$a" in
		--fail) fail=1 ;;
		--*) ;;
		-*) [[ "$a" == *f* ]] && fail=1 ;;
		*) out="${a##*/}" ;;
	esac
done
[ "$fail" == "1" ] && exit 22
echo "<html><body>404 Not Found</body></html>" > "$out"
exit 0
STUB
chmod +x "$WORK/bin/curl"

# check <dir> <script> <expected tarball> <args...>
check() {
	local dir="$1" script="$2" tarball="$3"; shift 3
	local sandbox="$WORK/$dir-${script%.sh}"
	mkdir -p "$sandbox" "$WORK/tmp"
	sed "s#/tmp/#$WORK/tmp/#g" "$REPO/$dir/$script" > "$sandbox/$script"
	chmod +x "$sandbox/$script"
	( cd "$sandbox" && PATH="$WORK/bin:$PATH" \
		./"$script" "$@" -p macos -x ) > "$sandbox.out" 2>&1
	local rc=$?
	if [ $rc -eq 0 ]; then
		echo "FAIL: $dir/$script exited 0 on a failed download"; FAILS=$((FAILS+1))
	elif [ -e "$sandbox/$tarball" ]; then
		echo "FAIL: $dir/$script left a bogus $tarball behind"; FAILS=$((FAILS+1))
	elif ! grep -q "Failed to download" "$sandbox.out"; then
		echo "FAIL: $dir/$script did not report the download failure"; FAILS=$((FAILS+1))
	else
		echo "ok:   $dir/$script"
	fi
}

check curl    libcurl-build.sh        curl-9.9.9.tar.gz     -v 9.9.9
check nghttp2 nghttp2-build.sh        nghttp2-9.9.9.tar.gz  -v 9.9.9
check openssl openssl-build-phase1.sh openssl-9.9.9.tar.gz  -v 9.9.9
check openssl openssl-build-phase2.sh openssl-9.9.9.tar.gz  -v 9.9.9

if [ $FAILS -ne 0 ]; then
	echo "$FAILS failure(s)"; exit 1
fi
echo "PASS"
