#!/bin/bash

# This script builds openssl+libcurl libraries for the Mac, iOS and tvOS 
#
# Jason Cox, @jasonacox
#   https://github.com/jasonacox/Build-OpenSSL-cURL

# HTTP2 Support?
NOHTTP2="/tmp/no-http2"
rm -f $NOHTTP2

usage ()
{
        echo "usage: $0 [-disable-http2]"
        exit 127
}

if [ "$1" == "-h" ]; then
        usage
fi

echo "Building OpenSSL"
cd openssl
./openssl-build.sh
cd ..

if [ "$1" == "-disable-http2" ]; then
	touch "$NOHTTP2"
else 
	echo "Building nghttp2 for HTTP2 support"
	cd nghttp2
	./nghttp2-build.sh
	cd ..
fi

echo
echo "Building Curl"
cd curl
./libcurl-build.sh
cd ..

echo 
echo "Libraries..."
echo
echo "opensll"
xcrun -sdk iphoneos lipo -info openssl/*/lib/*.a
echo
echo "nghttp2 (rename to libnghttp2.a)"
xcrun -sdk iphoneos lipo -info nghttp2/lib/*.a
echo
echo "libcurl (rename to libcurl.a)"
xcrun -sdk iphoneos lipo -info curl/lib/*.a

rm -f $NOHTTP2
