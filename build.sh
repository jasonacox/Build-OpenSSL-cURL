#!/bin/bash

# This script builds openssl+libcurl libraries for the Mac, iOS and tvOS 
#
# Jason Cox, @jasonacox
#   https://github.com/jasonacox/Build-OpenSSL-cURL
#

########################################
# EDIT this section to Select Versions #
########################################

OPENSSL="1.0.1t"
LIBCURL="7.50.1"
NGHTTP2="1.14.0"

########################################

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
./openssl-build.sh "$OPENSSL"
cd ..

if [ "$1" == "-disable-http2" ]; then
	touch "$NOHTTP2"
	NGHTTP2="NONE"	
else 
	echo "Building nghttp2 for HTTP2 support"
	cd nghttp2
	./nghttp2-build.sh "$NGHTTP2"
	cd ..
fi

echo
echo "Building Curl"
cd curl
./libcurl-build.sh "$LIBCURL"
cd ..

echo 
echo "Libraries..."
echo
echo "openssl [$OPENSSL]"
xcrun -sdk iphoneos lipo -info openssl/*/lib/*.a
echo
echo "nghttp2 (rename to libnghttp2.a) [$NGHTTP2]"
xcrun -sdk iphoneos lipo -info nghttp2/lib/*.a
echo
echo "libcurl (rename to libcurl.a) [$LIBCURL]"
xcrun -sdk iphoneos lipo -info curl/lib/*.a

echo
ARCHIVE="archive/libcurl-$LIBCURL-openssl-$OPENSSL-nghttp2-$NGHTTP2"
echo "Creating archive in $ARCHIVE..."
mkdir -p "$ARCHIVE"
cp curl/lib/*.a $ARCHIVE
cp openssl/*/lib/*.a $ARCHIVE
cp nghttp2/lib/*.a $ARCHIVE
echo "Archiving Mac binaries for curl and openssl..."
mv /tmp/curl $ARCHIVE
mv /tmp/openssl $ARCHIVE
$ARCHIVE/curl -V

rm -f $NOHTTP2
