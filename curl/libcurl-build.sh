#!/bin/bash

# This script downlaods and builds the iOS and Mac libcurl libraries with Bitcode enabled

# Credits:
#
# Felix Schwarz, IOSPIRIT GmbH, @@felix_schwarz.
#   https://gist.github.com/c61c0f7d9ab60f53ebb0.git
# Bochun Bai
#   https://github.com/sinofool/build-libcurl-ios
# Jason Cox, @jasonacox
#   https://github.com/jasonacox/Build-OpenSSL-cURL 

set -e

usage ()
{
	echo "usage: $0 [iOS SDK version (defaults to latest)] [tvOS SDK version (defaults to latest)]"
	exit 127
}

if [ $1 -e "-h" ]; then
	usage
fi

if [ -z $1 ]; then
	IOS_SDK_VERSION="" #"9.1"
	IOS_MIN_SDK_VERSION="8.0"
	
	TVOS_SDK_VERSION="" #"9.0"
	TVOS_MIN_SDK_VERSION="9.0"
else
	IOS_SDK_VERSION=$1
	TVOS_SDK_VERSION=$2
fi

CURL_VERSION="curl-7.37.1"
OPENSSL="${PWD}/../openssl"  
DEVELOPER=`xcode-select -print-path`
IPHONEOS_DEPLOYMENT_TARGET="6.0"

buildMac()
{
	ARCH=$1
	HOST="i386-apple-darwin"

	echo "Building ${CURL_VERSION} for ${ARCH}"

	TARGET="darwin-i386-cc"

	if [[ $ARCH == "x86_64" ]]; then
		TARGET="darwin64-x86_64-cc"
	fi

	export CC="${BUILD_TOOLS}/usr/bin/clang"
	export CFLAGS="-arch ${ARCH} -pipe -Os -gdwarf-2 -fembed-bitcode"
	export LDFLAGS="-arch ${ARCH} -L${OPENSSL}/Mac/lib"

	pushd . > /dev/null
	cd "${CURL_VERSION}"
	./configure -prefix="/tmp/${CURL_VERSION}-${ARCH}" -disable-shared --enable-static -with-random=/dev/urandom --with-ssl=${OPENSSL}/Mac --host=${HOST} &> "/tmp/${CURL_VERSION}-${ARCH}.log"
	make -j8 >> "/tmp/${CURL_VERSION}-${ARCH}.log" 2>&1
	make install >> "/tmp/${CURL_VERSION}-${ARCH}.log" 2>&1
	make clean >> "/tmp/${CURL_VERSION}-${ARCH}.log" 2>&1
	popd > /dev/null
}

buildIOS()
{
	ARCH=$1

	pushd . > /dev/null
	cd "${CURL_VERSION}"
  
	if [[ "${ARCH}" == "i386" || "${ARCH}" == "x86_64" ]]; then
		PLATFORM="iPhoneSimulator"
	else
		PLATFORM="iPhoneOS"
	fi
  
	export $PLATFORM
	export CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
	export CROSS_SDK="${PLATFORM}${IOS_SDK_VERSION}.sdk"
	export BUILD_TOOLS="${DEVELOPER}"
	export CC="${BUILD_TOOLS}/usr/bin/gcc"
	export CFLAGS="-arch ${ARCH} -pipe -Os -gdwarf-2 -isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -miphoneos-version-min=${IOS_MIN_SDK_VERSION} -fembed-bitcode"
	export LDFLAGS="-arch ${ARCH} -isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -L${OPENSSL}/iOS/lib"
   
	echo "Building ${CURL_VERSION} for ${PLATFORM} ${IOS_SDK_VERSION} ${ARCH}"

	if [[ "${ARCH}" == "arm64" ]]; then
		./configure -prefix="/tmp/${CURL_VERSION}-iOS-${ARCH}" -disable-shared --enable-static -with-random=/dev/urandom --with-ssl=${OPENSSL}/iOS --host="arm-apple-darwin" &> "/tmp/${CURL_VERSION}-iOS-${ARCH}.log"
	else
		./configure -prefix="/tmp/${CURL_VERSION}-iOS-${ARCH}" -disable-shared --enable-static -with-random=/dev/urandom --with-ssl=${OPENSSL}/iOS --host="${ARCH}-apple-darwin" &> "/tmp/${CURL_VERSION}-iOS-${ARCH}.log"
	fi

	make -j8 >> "/tmp/${CURL_VERSION}-iOS-${ARCH}.log" 2>&1
	make install >> "/tmp/${CURL_VERSION}-iOS-${ARCH}.log" 2>&1
	make clean >> "/tmp/${CURL_VERSION}-iOS-${ARCH}.log" 2>&1
	popd > /dev/null
}

buildTVOS()
{
	ARCH=$1

	pushd . > /dev/null
	cd "${CURL_VERSION}"
  
	if [[ "${ARCH}" == "i386" || "${ARCH}" == "x86_64" ]]; then
		PLATFORM="AppleTVSimulator"
	else
		PLATFORM="AppleTVOS"
	fi
  
	export $PLATFORM
	export CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
	export CROSS_SDK="${PLATFORM}${TVOS_SDK_VERSION}.sdk"
	export BUILD_TOOLS="${DEVELOPER}"
	export CC="${BUILD_TOOLS}/usr/bin/gcc"
	export CFLAGS="-arch ${ARCH} -pipe -Os -gdwarf-2 -isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -mtvos-version-min=${TVOS_MIN_SDK_VERSION} -fembed-bitcode"
	export LDFLAGS="-arch ${ARCH} -isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -L${OPENSSL}/tvOS/lib"
   
	echo "Building ${CURL_VERSION} for ${PLATFORM} ${TVOS_SDK_VERSION} ${ARCH}"

	./configure -prefix="/tmp/${CURL_VERSION}-tvOS-${ARCH}" --host="arm-apple-darwin" -disable-shared -with-random=/dev/urandom --disable-ntlm-wb --with-ssl="${OPENSSL}/tvOS" &> "/tmp/${CURL_VERSION}-tvOS-${ARCH}.log"

	# Patch to not use fork() since it's not available on tvOS
        LANG=C sed -i -- 's/define HAVE_FORK 1/define HAVE_FORK 0/' "./lib/curl_config.h"
        LANG=C sed -i -- 's/HAVE_FORK"]=" 1"/HAVE_FORK\"]=" 0"/' "config.status"

	make -j8 >> "/tmp/${CURL_VERSION}-tvOS-${ARCH}.log" 2>&1
	make install >> "/tmp/${CURL_VERSION}-tvOS-${ARCH}.log" 2>&1
	make clean >> "/tmp/${CURL_VERSION}-tvOS-${ARCH}.log" 2>&1
	popd > /dev/null
}


echo "Cleaning up"
rm -rf include/curl/* lib/*

mkdir -p lib
mkdir -p include/curl/

rm -rf "/tmp/${CURL_VERSION}-*"
rm -rf "/tmp/${CURL_VERSION}-*.log"

rm -rf "${CURL_VERSION}"

if [ ! -e ${CURL_VERSION}.tar.gz ]; then
	echo "Downloading ${CURL_VERSION}.tar.gz"
	curl -O http://curl.haxx.se/download/${CURL_VERSION}.tar.gz
else
	echo "Using ${CURL_VERSION}.tar.gz"
fi


echo "Unpacking curl"
tar xfz "${CURL_VERSION}.tar.gz"

buildMac "x86_64"

echo "Copying headers"
cp /tmp/${CURL_VERSION}-x86_64/include/curl/* include/curl/

echo "Building Mac libraries"
lipo \
	"/tmp/${CURL_VERSION}-x86_64/lib/libcurl.a" \
	-create -output lib/libcurl_Mac.a

buildIOS "armv7"
buildIOS "armv7s"
buildIOS "arm64"
buildIOS "x86_64"
buildIOS "i386"

echo "Building iOS libraries"
lipo \
	"/tmp/${CURL_VERSION}-iOS-armv7/lib/libcurl.a" \
	"/tmp/${CURL_VERSION}-iOS-armv7s/lib/libcurl.a" \
	"/tmp/${CURL_VERSION}-iOS-i386/lib/libcurl.a" \
	"/tmp/${CURL_VERSION}-iOS-arm64/lib/libcurl.a" \
	"/tmp/${CURL_VERSION}-iOS-x86_64/lib/libcurl.a" \
	-create -output lib/libcurl_iOS.a

buildTVOS "arm64"
buildTVOS "x86_64"

echo "Building tvOS libraries"
lipo \
	"/tmp/${CURL_VERSION}-tvOS-arm64/lib/libcurl.a" \
	"/tmp/${CURL_VERSION}-tvOS-x86_64/lib/libcurl.a" \
	-create -output lib/libcurl_tvOS.a

echo "Cleaning up"
rm -rf /tmp/${CURL_VERSION}-*
rm -rf ${CURL_VERSION}

echo "Checking libraries"
xcrun -sdk iphoneos lipo -info lib/*.a

echo "Done"
