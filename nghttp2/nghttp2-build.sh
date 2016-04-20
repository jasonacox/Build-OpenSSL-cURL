#!/bin/bash
# This script downlaods and builds the Mac, iOS and tvOS nghttp2 libraries 
#
# Credits:
# Jason Cox, @jasonacox
#   https://github.com/jasonacox/Build-OpenSSL-cURL 
#
# NGHTTP2 - https://github.com/nghttp2/nghttp2
#

# > nghttp2 is an implementation of HTTP/2 and its header 
# > compression algorithm HPACK in C
 
set -e

usage ()
{
	echo "usage: $0 [iOS SDK version (defaults to latest)] [tvOS SDK version (defaults to latest)]"
	exit 127
}

if [ "$1" == "-h" ]; then
	usage
fi

if [ -z $1 ]; then
	IOS_SDK_VERSION="" #"9.1"
	IOS_MIN_SDK_VERSION="7.1"
	
	TVOS_SDK_VERSION="" #"9.0"
	TVOS_MIN_SDK_VERSION="9.0"
else
	IOS_SDK_VERSION=$1
	TVOS_SDK_VERSION=$2
fi

# --- Edit this to update version ---
NGHTTP2_VERNUM="1.9.2"

NGHTTP2_VERSION="nghttp2-${NGHTTP2_VERNUM}"
DEVELOPER=`xcode-select -print-path`

NGHTTP2="${PWD}/../nghttp2"

buildMac()
{
	ARCH=$1
        HOST="i386-apple-darwin"

	echo "Building ${NGHTTP2_VERSION} for ${ARCH}"

	TARGET="darwin-i386-cc"

	if [[ $ARCH == "x86_64" ]]; then
		TARGET="darwin64-x86_64-cc"
	fi

	export CC="${BUILD_TOOLS}/usr/bin/clang -fembed-bitcode"
        export CFLAGS="-arch ${ARCH} -pipe -Os -gdwarf-2 -fembed-bitcode"
        export LDFLAGS="-arch ${ARCH}"

	pushd . > /dev/null
	cd "${NGHTTP2_VERSION}"
	./configure --disable-app --disable-threads --enable-lib-only --prefix="${NGHTTP2}/Mac/${ARCH}" --host=${HOST} &> "/tmp/${NGHTTP2_VERSION}-${ARCH}.log"
	make >> "/tmp/${NGHTTP2_VERSION}-${ARCH}.log" 2>&1
	make install >> "/tmp/${NGHTTP2_VERSION}-${ARCH}.log" 2>&1
	make clean >> "/tmp/${NGHTTP2_VERSION}-${ARCH}.log" 2>&1
	popd > /dev/null
}

buildIOS()
{
	ARCH=$1
	BITCODE=$2

	pushd . > /dev/null
	cd "${NGHTTP2_VERSION}"
  
	if [[ "${ARCH}" == "i386" || "${ARCH}" == "x86_64" ]]; then
		PLATFORM="iPhoneSimulator"
	else
		PLATFORM="iPhoneOS"
	fi

        if [[ "${BITCODE}" == "nobitcode" ]]; then
                CC_BITCODE_FLAG=""
        else
                CC_BITCODE_FLAG="-fembed-bitcode"
        fi
  
	export $PLATFORM
	export CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
	export CROSS_SDK="${PLATFORM}${IOS_SDK_VERSION}.sdk"
	export BUILD_TOOLS="${DEVELOPER}"
	export CC="${BUILD_TOOLS}/usr/bin/gcc"
	export CFLAGS="-arch ${ARCH} -pipe -Os -gdwarf-2 -isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -miphoneos-version-min=${IOS_MIN_SDK_VERSION} ${CC_BITCODE_FLAG}"
        export LDFLAGS="-arch ${ARCH} -isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK}"
   
	echo "Building ${NGHTTP2_VERSION} for ${PLATFORM} ${IOS_SDK_VERSION} ${ARCH}"
        if [[ "${ARCH}" == "arm64" ]]; then
		./configure --disable-shared --disable-app --disable-threads --enable-lib-only  --prefix="${NGHTTP2}/iOS/${ARCH}" --host="arm-apple-darwin" &> "/tmp/${NGHTTP2_VERSION}-iOS-${ARCH}-${BITCODE}.log"
        else
		./configure --disable-shared --disable-app --disable-threads --enable-lib-only --prefix="${NGHTTP2}/iOS/${ARCH}" --host="${ARCH}-apple-darwin" &> "/tmp/${NGHTTP2_VERSION}-iOS-${ARCH}-${BITCODE}.log"
        fi

        make -j8 >> "/tmp/${NGHTTP2_VERSION}-iOS-${ARCH}-${BITCODE}.log" 2>&1
        make install >> "/tmp/${NGHTTP2_VERSION}-iOS-${ARCH}-${BITCODE}.log" 2>&1
        make clean >> "/tmp/${NGHTTP2_VERSION}-iOS-${ARCH}-${BITCODE}.log" 2>&1
        popd > /dev/null
}

buildTVOS()
{
	ARCH=$1

	pushd . > /dev/null
	cd "${NGHTTP2_VERSION}"
  
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
        export LDFLAGS="-arch ${ARCH} -isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -L${OPENSSL}/tvOS/lib ${NGHTTP2LIB}"
	export LC_CTYPE=C
   
	echo "Building ${NGHTTP2_VERSION} for ${PLATFORM} ${TVOS_SDK_VERSION} ${ARCH}"

	# Patch apps/speed.c to not use fork() since it's not available on tvOS
	# LANG=C sed -i -- 's/define HAVE_FORK 1/define HAVE_FORK 0/' "./apps/speed.c"

	# Patch Configure to build for tvOS, not iOS
	# LANG=C sed -i -- 's/D\_REENTRANT\:iOS/D\_REENTRANT\:tvOS/' "./Configure"
	# chmod u+x ./Configure
	
	./configure --disable-shared --disable-app --disable-threads --enable-lib-only  --prefix="${NGHTTP2}/tvOS/${ARCH}" --host="arm-apple-darwin" &> "/tmp/${CURL_VERSION}-tvOS-${ARCH}.log"
	LANG=C sed -i -- 's/define HAVE_FORK 1/define HAVE_FORK 0/' "config.h"

	# add -isysroot to CC=
	#sed -ie "s!^CFLAG=!CFLAG=-isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -mtvos-version-min=${TVOS_MIN_SDK_VERSION} !" "Makefile"

	make  >> "/tmp/${NGHTTP2_VERSION}-tvOS-${ARCH}.log" 2>&1
	make install  >> "/tmp/${NGHTTP2_VERSION}-tvOS-${ARCH}.log" 2>&1
	make clean >> "/tmp/${NGHTTP2_VERSION}-tvOS-${ARCH}.log" 2>&1
	popd > /dev/null
}


echo "Cleaning up"
rm -rf include/nghttp2/* lib/*
rm -fr Mac
rm -fr iOS
rm -fr tvOS

mkdir -p lib

rm -rf "/tmp/${NGHTTP2_VERSION}-*"
rm -rf "/tmp/${NGHTTP2_VERSION}-*.log"

rm -rf "${NGHTTP2_VERSION}"

if [ ! -e ${NGHTTP2_VERSION}.tar.gz ]; then
	echo "Downloading ${NGHTTP2_VERSION}.tar.gz"
	curl -LO https://github.com/nghttp2/nghttp2/releases/download/v${NGHTTP2_VERNUM}/${NGHTTP2_VERSION}.tar.gz
else
	echo "Using ${NGHTTP2_VERSION}.tar.gz"
fi

echo "Unpacking nghttp2"
tar xfz "${NGHTTP2_VERSION}.tar.gz"

echo "Building Mac libraries"
buildMac "x86_64"

lipo \
        "${NGHTTP2}/Mac/x86_64/lib/libnghttp2.a" \
        -create -output "${NGHTTP2}/lib/libnghttp2_Mac.a"

echo "Building iOS libraries (bitcode)"
buildIOS "armv7" "bitcode"
buildIOS "armv7s" "bitcode"
buildIOS "arm64" "bitcode"
buildIOS "x86_64" "bitcode"
buildIOS "i386" "bitcode"

lipo \
	"${NGHTTP2}/iOS/armv7/lib/libnghttp2.a" \
	"${NGHTTP2}/iOS/armv7s/lib/libnghttp2.a" \
	"${NGHTTP2}/iOS/i386/lib/libnghttp2.a" \
	"${NGHTTP2}/iOS/arm64/lib/libnghttp2.a" \
	"${NGHTTP2}/iOS/x86_64/lib/libnghttp2.a" \
	-create -output "${NGHTTP2}/lib/libnghttp2_iOS.a"

echo "Building tvOS libraries"
buildTVOS "arm64"
buildTVOS "x86_64"

lipo \
        "${NGHTTP2}/tvOS/arm64/lib/libnghttp2.a" \
        "${NGHTTP2}/tvOS/x86_64/lib/libnghttp2.a" \
        -create -output "${NGHTTP2}/lib/libnghttp2_tvOS.a"

echo "Cleaning up"
rm -rf /tmp/${NGHTTP2_VERSION}-*
rm -rf ${NGHTTP2_VERSION}

echo "Done"
