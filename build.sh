#!/bin/bash

# This script builds openssl+libcurl libraries for the Mac, iOS and tvOS 
#
# Jason Cox, @jasonacox
#   https://github.com/jasonacox/Build-OpenSSL-cURL
#

################################################
# EDIT this section to Select Default Versions #
################################################

OPENSSL="1.1.1d"	# https://www.openssl.org/source/
LIBCURL="7.68.0"	# https://curl.haxx.se/download.html
NGHTTP2="1.40.0"	# https://nghttp2.org/

################################################

# HTTP2 Support?
NOHTTP2="/tmp/no-http2"
rm -f $NOHTTP2

# Global flags
engine=0
disablehttp2=0
disablebitcode=0

usage ()
{
    echo
	echo "Usage:"
	echo
	echo "  $0 [-o <OpenSSL version>] [-c <curl version>] [-n <nghttp2 version] [-d] [-e] [-h]"
	echo 
	echo "         -o <version>   Build OpenSSL version (default $OPENSSL)"
	echo "         -c <version>   Build curl version (default $LIBCURL)"
	echo "         -n <version>   Build nghttp2 version (default $NGHTTP2)"
	echo "         -d             Compile without HTTP2 support"
	echo "         -e             Compile with OpenSSL engine support"
	echo "         -b             Compile without bitcode"
	echo "         -h             Show usage"
	echo 
    exit 127
}

while getopts "o:c:n:deh\?" o; do
    case "${o}" in
		o)
			OPENSSL="${OPTARG}"
			;;
		c)
			LIBCURL="${OPTARG}"
			;;
		n)
			NGHTTP2="${OPTARG}"
			;;
		d)
			disablehttp2=1
			;;
		e)
			engine=1
			;;
		b)
			disablebitcode=1
			;;
		*)
			usage
			;;
    esac
done
shift $((OPTIND-1))

## OpenSSL Build
echo
cd openssl 
if [ "$engine" == "1" ]; then
        echo "Building OpenSSL with engine support"
	./openssl-build.sh -v "$OPENSSL" -e
else
	echo "Building OpenSSL"
	./openssl-build.sh -v "$OPENSSL"
fi
cd ..

## Nghttp2 Build
if [ "$disablehttp2" == "1" ]; then
	touch "$NOHTTP2"
	NGHTTP2="NONE"	
else 
	echo
	echo "Building nghttp2 for HTTP2 support"
	cd nghttp2
	./nghttp2-build.sh -v "$NGHTTP2"
	cd ..
fi

## Curl Build
echo
echo "Building Curl"
cd curl
if [ "$disablebitcode" == "1" ]; then
	./libcurl-build.sh -v "$LIBCURL" -b
else 
	./libcurl-build.sh -v "$LIBCURL"
fi
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
echo "Creating archive in $ARCHIVE for release v$LIBCURL..."
mkdir -p "$ARCHIVE"
mkdir -p "$ARCHIVE/include/openssl"
mkdir -p "$ARCHIVE/include/curl"
mkdir -p "$ARCHIVE/lib/iOS"
mkdir -p "$ARCHIVE/lib/MacOS"
mkdir -p "$ARCHIVE/lib/tvOS"
mkdir -p "$ARCHIVE/bin"
# archive libraries
cp curl/lib/libcurl_iOS.a $ARCHIVE/lib/iOS/libcurl.a
cp curl/lib/libcurl_tvOS.a $ARCHIVE/lib/tvOS/libcurl.a
cp curl/lib/libcurl_Mac.a $ARCHIVE/lib/MacOS/libcurl.a
cp openssl/iOS/lib/libcrypto.a $ARCHIVE/lib/iOS/libcrypto.a
cp openssl/tvOS/lib/libcrypto.a $ARCHIVE/lib/tvOS/libcrypto.a
cp openssl/Mac/lib/libcrypto.a $ARCHIVE/lib/MacOS/libcrypto.a
cp openssl/iOS/lib/libssl.a $ARCHIVE/lib/iOS/libssl.a
cp openssl/tvOS/lib/libssl.a $ARCHIVE/lib/tvOS/libssl.a
cp openssl/Mac/lib/libssl.a $ARCHIVE/lib/MacOS/libssl.a
cp nghttp2/lib/libnghttp2_iOS.a $ARCHIVE/lib/iOS/libnghttp2.a
cp nghttp2/lib/libnghttp2_tvOS.a $ARCHIVE/lib/tvOS/libnghttp2.a
cp nghttp2/lib/libnghttp2_Mac.a $ARCHIVE/lib/MacOS/libnghttp2.a
# archive header files
cp openssl/iOS/include/openssl/* "$ARCHIVE/include/openssl"
cp curl/include/curl/* "$ARCHIVE/include/curl"
# archive root certs
curl -s https://curl.haxx.se/ca/cacert.pem > $ARCHIVE/cacert.pem
sed -e "s/ZZZLIBCURL/$LIBCURL/g" -e "s/ZZZOPENSSL/$OPENSSL/g" -e "s/ZZZNGHTTP2/$NGHTTP2/g" archive/release-template.md > $ARCHIVE/README.md
echo
echo "Copying libraries into $EXAMPLE..."
cp openssl/iOS/lib/libcrypto.a "$EXAMPLE/libs/libcrypto.a"
cp openssl/iOS/lib/libssl.a "$EXAMPLE/libs/libssl.a"
cp openssl/iOS/include/openssl/* "$EXAMPLE/include/openssl/"
cp curl/include/curl/* "$EXAMPLE/include/curl/"
cp curl/lib/libcurl_iOS.a "$EXAMPLE/libs/libcurl.a"
cp nghttp2/lib/libnghttp2_iOS.a "$EXAMPLE/libs/libnghttp2.a"
cp $ARCHIVE/cacert.pem "$EXAMPLE/cacert.pem"
echo
echo "Archiving Mac binaries for curl and openssl..."
mv /tmp/curl $ARCHIVE/bin
mv /tmp/openssl $ARCHIVE/bin
echo
echo "Testing Mac curl binary..."
$ARCHIVE/bin/curl -V

rm -f $NOHTTP2
