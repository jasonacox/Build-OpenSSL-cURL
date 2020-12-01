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
# 
# NOTE: pkg-config is required
 
set -e

# Formatting
default="\033[39m"
wihte="\033[97m"
green="\033[32m"
red="\033[91m"
yellow="\033[33m"

bold="\033[0m${green}\033[1m"
subbold="\033[0m${green}"
archbold="\033[0m${yellow}\033[1m"
normal="${white}\033[0m"
dim="\033[0m${white}\033[2m"
alert="\033[0m${red}\033[1m"
alertdim="\033[0m${red}\033[2m"

# set trap to help debug build errors
trap 'echo -e "${alert}** ERROR with Build - Check /tmp/nghttp2*.log${alertdim}"; tail -5 /tmp/nghttp2*.log' INT TERM EXIT

# --- Edit this to update default version ---
NGHTTP2_VERNUM="1.41.0"
IOS_MIN_SDK_VERSION="7.1"
IOS_SDK_VERSION=""
TVOS_MIN_SDK_VERSION="9.0"
TVOS_SDK_VERSION=""
catalyst="0"

CORES=$(sysctl -n hw.ncpu)

usage ()
{
	echo
	echo -e "${bold}Usage:${normal}"
	echo
    echo -e "  ${subbold}$0${normal} [-v ${dim}<nghttp2 version>${normal}] [-s ${dim}<iOS SDK version>${normal}] [-t ${dim}<tvOS SDK version>${normal}] [-m] [-x] [-h]"
    echo
	echo "         -v   version of nghttp2 (default $NGHTTP2_VERNUM)"
	echo "         -s   iOS SDK version (default $IOS_MIN_SDK_VERSION)"
	echo "         -t   tvOS SDK version (default $TVOS_MIN_SDK_VERSION)"
	echo "         -m   compile Mac Catalyst library [beta]"
	echo "         -x   disable color output"
	echo "         -h   show usage"	
	echo
	trap - INT TERM EXIT
	exit 127
}

while getopts "v:s:t:mxh\?" o; do
    case "${o}" in
        v)
            NGHTTP2_VERNUM="${OPTARG}"
            ;;
        s)
            IOS_SDK_VERSION="${OPTARG}"
            ;;
        t)
            TVOS_SDK_VERSION="${OPTARG}"
            ;;
        m)
            catalyst="1"
            ;;
        x)
            bold=""
            subbold=""
            normal=""
            dim=""
            alert=""
            alertdim=""
            archbold=""
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

NGHTTP2_VERSION="nghttp2-${NGHTTP2_VERNUM}"
DEVELOPER=`xcode-select -print-path`

NGHTTP2="${PWD}/../nghttp2"

# Check to see if pkg-config is already installed
if (type "pkg-config" > /dev/null 2>&1 ) ; then
	echo "  pkg-config already installed"
else
	echo -e "${alertdim}** WARNING: pkg-config not installed... attempting to install.${dim}"

	# Check to see if Brew is installed
	if (type "brew" > /dev/null 2>&1 ) ; then
		echo "  brew installed - using to install pkg-config"
		brew install pkg-config
	else
		# Build pkg-config from Source
		curl -LO https://pkg-config.freedesktop.org/releases/pkg-config-0.29.2.tar.gz
		echo "  Building pkg-config"
		tar xfz pkg-config-0.29.2.tar.gz
		cd pkg-config-0.29.2
		./configure --prefix=/tmp/pkg_config --with-internal-glib >> "/tmp/${NGHTTP2_VERSION}.log" 2>&1
		make -j${CORES} >> "/tmp/${NGHTTP2_VERSION}.log" 2>&1
		make install >> "/tmp/${NGHTTP2_VERSION}.log" 2>&1
		PATH=$PATH:/tmp/pkg_config/bin
	fi

	# Check to see if installation worked
	if (type "pkg-config" > /dev/null 2>&1 ) ; then
		echo "  SUCCESS: pkg-config installed"
	else
		echo -e "${alert}** FATAL ERROR: pkg-config failed to install - exiting.${normal}"
		exit 1
	fi
fi 

buildMac()
{
	ARCH=$1

	echo -e "${subbold}Building ${NGHTTP2_VERSION} for ${archbold}${ARCH}${dim}"

	TARGET="darwin-i386-cc"

	if [[ $ARCH == "x86_64" ]]; then
		TARGET="darwin64-x86_64-cc"
	fi

	export CC="${BUILD_TOOLS}/usr/bin/gcc -fembed-bitcode"
        export CFLAGS="-arch ${ARCH} -pipe -Os -gdwarf-2 -fembed-bitcode"
        export LDFLAGS="-arch ${ARCH}"

	pushd . > /dev/null
	cd "${NGHTTP2_VERSION}"
	./configure --disable-shared --disable-app --disable-threads --enable-lib-only --prefix="${NGHTTP2}/Mac/${ARCH}" &> "/tmp/${NGHTTP2_VERSION}-${ARCH}.log"
	make -j${CORES} >> "/tmp/${NGHTTP2_VERSION}-${ARCH}.log" 2>&1
	make install >> "/tmp/${NGHTTP2_VERSION}-${ARCH}.log" 2>&1
	make clean >> "/tmp/${NGHTTP2_VERSION}-${ARCH}.log" 2>&1
	popd > /dev/null
}

buildCatalyst()
{
	ARCH=$1

	echo -e "${subbold}Building ${NGHTTP2_VERSION} for ${archbold}${ARCH}${dim}"

	TARGET="darwin64-${ARCH}-cc"

	export CC="${BUILD_TOOLS}/usr/bin/gcc -fembed-bitcode -arch ${ARCH} -target x86_64-apple-ios13.0-macabi"

    export CFLAGS="-arch ${ARCH} -pipe -Os -gdwarf-2 -fembed-bitcode"
    export LDFLAGS="-arch ${ARCH}"

	pushd . > /dev/null
	cd "${NGHTTP2_VERSION}"
	./configure --disable-shared --disable-app --disable-threads --enable-lib-only --prefix="${NGHTTP2}/Catalyst/${ARCH}" &> "/tmp/${NGHTTP2_VERSION}-catalyst-${ARCH}.log"
	make -j${CORES} >> "/tmp/${NGHTTP2_VERSION}-catalyst-${ARCH}.log" 2>&1
	make install >> "/tmp/${NGHTTP2_VERSION}-catalyst-${ARCH}.log" 2>&1
	make clean >> "/tmp/${NGHTTP2_VERSION}-catalyst-${ARCH}.log" 2>&1
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
   
	echo -e "${subbold}Building ${NGHTTP2_VERSION} for ${PLATFORM} ${IOS_SDK_VERSION} ${archbold}${ARCH}${dim}"
        if [[ "${ARCH}" == "arm64" || "${ARCH}" == "arm64e"  ]]; then
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
	export LDFLAGS="-arch ${ARCH} -isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} ${NGHTTP2LIB}"
	export LC_CTYPE=C
  
	echo -e "${subbold}Building ${NGHTTP2_VERSION} for ${PLATFORM} ${TVOS_SDK_VERSION} ${archbold}${ARCH}${dim}"

	# Patch apps/speed.c to not use fork() since it's not available on tvOS
	# LANG=C sed -i -- 's/define HAVE_FORK 1/define HAVE_FORK 0/' "./apps/speed.c"

	# Patch Configure to build for tvOS, not iOS
	# LANG=C sed -i -- 's/D\_REENTRANT\:iOS/D\_REENTRANT\:tvOS/' "./Configure"
	# chmod u+x ./Configure
	
	./configure --disable-shared --disable-app --disable-threads --enable-lib-only  --prefix="${NGHTTP2}/tvOS/${ARCH}" --host="arm-apple-darwin" &> "/tmp/${NGHTTP2_VERSION}-tvOS-${ARCH}.log"
	LANG=C sed -i -- 's/define HAVE_FORK 1/define HAVE_FORK 0/' "config.h"

	# add -isysroot to CC=
	#sed -ie "s!^CFLAG=!CFLAG=-isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -mtvos-version-min=${TVOS_MIN_SDK_VERSION} !" "Makefile"

	make -j8 >> "/tmp/${NGHTTP2_VERSION}-tvOS-${ARCH}.log" 2>&1
	make install  >> "/tmp/${NGHTTP2_VERSION}-tvOS-${ARCH}.log" 2>&1
	make clean >> "/tmp/${NGHTTP2_VERSION}-tvOS-${ARCH}.log" 2>&1
	popd > /dev/null
}

echo -e "${bold}Cleaning up${dim}"
rm -rf include/nghttp2/* lib/*
rm -fr Mac
rm -fr iOS
rm -fr tvOS
rm -fr Catalyst

mkdir -p lib
mkdir -p Mac
mkdir -p iOS
mkdir -p tvOS
mkdir -p Catalyst

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

echo -e "${bold}Building Mac libraries${dim}"
buildMac "x86_64"

lipo \
        "${NGHTTP2}/Mac/x86_64/lib/libnghttp2.a" \
        -create -output "${NGHTTP2}/lib/libnghttp2_Mac.a"

if [ $catalyst == "1" ]; then
echo -e "${bold}Building Catalyst libraries${dim}"
buildCatalyst "x86_64"

lipo \
        "${NGHTTP2}/Catalyst/x86_64/lib/libnghttp2.a" \
        -create -output "${NGHTTP2}/lib/libnghttp2_Catalyst.a"
fi

echo -e "${bold}Building iOS libraries (bitcode)${dim}"
buildIOS "armv7" "bitcode"
buildIOS "armv7s" "bitcode"
buildIOS "arm64" "bitcode"
buildIOS "arm64e" "bitcode"
buildIOS "x86_64" "bitcode"
buildIOS "i386" "bitcode"

lipo \
	"${NGHTTP2}/iOS/armv7/lib/libnghttp2.a" \
	"${NGHTTP2}/iOS/armv7s/lib/libnghttp2.a" \
	"${NGHTTP2}/iOS/i386/lib/libnghttp2.a" \
	"${NGHTTP2}/iOS/arm64/lib/libnghttp2.a" \
	"${NGHTTP2}/iOS/arm64e/lib/libnghttp2.a" \
	"${NGHTTP2}/iOS/x86_64/lib/libnghttp2.a" \
	-create -output "${NGHTTP2}/lib/libnghttp2_iOS-fat.a"

lipo \
	"${NGHTTP2}/iOS/armv7/lib/libnghttp2.a" \
	"${NGHTTP2}/iOS/armv7s/lib/libnghttp2.a" \
	"${NGHTTP2}/iOS/arm64/lib/libnghttp2.a" \
	"${NGHTTP2}/iOS/arm64e/lib/libnghttp2.a" \
	-create -output "${NGHTTP2}/lib/libnghttp2_iOS.a"

lipo \
	"${NGHTTP2}/iOS/i386/lib/libnghttp2.a" \
	"${NGHTTP2}/iOS/x86_64/lib/libnghttp2.a" \
	-create -output "${NGHTTP2}/lib/libnghttp2_iOS-simulator.a"

echo -e "${bold}Building tvOS libraries${dim}"
buildTVOS "arm64"
buildTVOS "x86_64"

lipo \
        "${NGHTTP2}/tvOS/arm64/lib/libnghttp2.a" \
        "${NGHTTP2}/tvOS/x86_64/lib/libnghttp2.a" \
        -create -output "${NGHTTP2}/lib/libnghttp2_tvOS.a"

echo -e "${bold}Cleaning up${dim}"
rm -rf /tmp/${NGHTTP2_VERSION}-*
rm -rf ${NGHTTP2_VERSION}

#reset trap
trap - INT TERM EXIT

echo -e "${normal}Done"

