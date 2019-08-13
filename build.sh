#!/bin/bash

# This script builds openssl+libcurl libraries for the Mac, iOS and tvOS 
#
# Jason Cox, @jasonacox
#   https://github.com/jasonacox/Build-OpenSSL-cURL
#

########################################
# EDIT this section to Select Versions #
########################################

OPENSSL="1.1.1c"
LIBCURL="7.65.3"
NGHTTP2="1.39.1"

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

echo
echo "Building OpenSSL"
cd openssl 
./openssl-build.sh "$OPENSSL"
cd ..

if [ "$1" == "-disable-http2" ]; then
	touch "$NOHTTP2"
	NGHTTP2="NONE"	
else 
	echo
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

EXAMPLE="examples/iOS Test App"
ARCHIVE="archive/libcurl-$LIBCURL-openssl-$OPENSSL-nghttp2-$NGHTTP2"

echo
echo "Creating archive in $ARCHIVE..."
mkdir -p "$ARCHIVE"
cp curl/lib/*.a $ARCHIVE
cp openssl/iOS/lib/libcrypto.a $ARCHIVE/libcrypto_iOS.a
cp openssl/tvOS/lib/libcrypto.a $ARCHIVE/libcrypto_tvOS.a
cp openssl/Mac/lib/libcrypto.a $ARCHIVE/libcrypto_Mac.a
cp openssl/iOS/lib/libssl.a $ARCHIVE/libssl_iOS.a
cp openssl/tvOS/lib/libssl.a $ARCHIVE/libssl_tvOS.a
cp openssl/Mac/lib/libssl.a $ARCHIVE/libssl_Mac.a
cp nghttp2/lib/*.a $ARCHIVE
curl -s https://curl.haxx.se/ca/cacert.pem > $ARCHIVE/cacert.pem
echo
echo "Copying libraries into $EXAMPLE..."
cp openssl/iOS/lib/libcrypto.a "$EXAMPLE/libs/libcrypto.a"
cp openssl/iOS/lib/libssl.a "$EXAMPLE/libs/libssl.a"
cp openssl/iOS/include/openssl/* "$EXAMPLE/include/openssl/"
cp curl/include/curl/* "$EXAMPLE/include/curl/"
cp curl/lib/libcurl_iOS.a "$EXAMPLE/libs/libcurl.a"
cp nghttp2/lib/libnghttp2_iOS.a "$EXAMPLE/libs/libnghttp2.a"
cp $ARCHIVE/cacert.pem "$EXAMPLE/cacert.pem"
cp -r "$EXAMPLE/include" "$ARCHIVE"
echo
echo "Archiving Mac binaries for curl and openssl..."
mv /tmp/curl $ARCHIVE
mv /tmp/openssl $ARCHIVE
echo
echo "Testing Mac curl binary..."
$ARCHIVE/curl -V

rm -f $NOHTTP2
