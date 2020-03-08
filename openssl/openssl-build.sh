#!/bin/bash

# This script downlaods and builds the Mac, iOS and tvOS openSSL libraries with Bitcode enabled

# Credits:
#
# Stefan Arentz
#   https://github.com/st3fan/ios-openssl
# Felix Schulze
#   https://github.com/x2on/OpenSSL-for-iPhone/blob/master/build-libssl.sh
# James Moore
#   https://gist.github.com/foozmeat/5154962
# Peter Steinberger, PSPDFKit GmbH, @steipete.
#   https://gist.github.com/felix-schwarz/c61c0f7d9ab60f53ebb0
# Jason Cox, @jasonacox
#   https://github.com/jasonacox/Build-OpenSSL-cURL

set -e

# Custom build options
CUSTOMCONFIG="enable-ssl-trace"

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
trap 'echo -e "${alert}** ERROR with Build - Check /tmp/openssl*.log${alertdim}"; tail -3 /tmp/openssl*.log' INT TERM EXIT

OPENSSL_VERSION="openssl-1.1.1d"
IOS_MIN_SDK_VERSION="7.1"
IOS_SDK_VERSION=""
TVOS_MIN_SDK_VERSION="9.0"
TVOS_SDK_VERSION=""

usage ()
{
	echo
	echo -e "${bold}Usage:${normal}"
	echo
	echo -e "  ${subbold}$0${normal} [-v ${dim}<openssl version>${normal}] [-s ${dim}<iOS SDK version>${normal}] [-t ${dim}<tvOS SDK version>${normal}] [-e] [-x] [-h]"
	echo
	echo "         -v   version of OpenSSL (default $OPENSSL_VERSION)"
	echo "         -s   iOS SDK version (default $IOS_MIN_SDK_VERSION)"
	echo "         -t   tvOS SDK version (default $TVOS_MIN_SDK_VERSION)"
	echo "         -e   compile with engine support"	
	echo "         -x   disable color output"
	echo "         -h   show usage"	
	echo
	trap - INT TERM EXIT
	exit 127
}

engine=0

while getopts "v:s:t:exh\?" o; do
    case "${o}" in
        v)
	    	OPENSSL_VERSION="openssl-${OPTARG}"
            ;;
        s)
            IOS_SDK_VERSION="${OPTARG}"
            ;;
        t)
	    	TVOS_SDK_VERSION="${OPTARG}"
            ;;
		e)
            engine=1
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

DEVELOPER=`xcode-select -print-path`

buildMac()
{
	ARCH=$1

	echo -e "${subbold}Building ${OPENSSL_VERSION} for ${archbold}${ARCH}${dim}"

	TARGET="darwin-i386-cc"

	if [[ $ARCH == "x86_64" ]]; then
		TARGET="darwin64-x86_64-cc"
	fi

	export CC="${BUILD_TOOLS}/usr/bin/clang"

	pushd . > /dev/null
	cd "${OPENSSL_VERSION}"
	if [[ "$OPENSSL_VERSION" = "openssl-1.1.1"* ]]; then
		./Configure no-asm ${TARGET} -no-shared  --prefix="/tmp/${OPENSSL_VERSION}-${ARCH}" --openssldir="/tmp/${OPENSSL_VERSION}-${ARCH}" $CUSTOMCONFIG &> "/tmp/${OPENSSL_VERSION}-${ARCH}.log"
	else
		./Configure no-asm ${TARGET} -no-shared  --openssldir="/tmp/${OPENSSL_VERSION}-${ARCH}" $CUSTOMCONFIG &> "/tmp/${OPENSSL_VERSION}-${ARCH}.log"
	fi
	make >> "/tmp/${OPENSSL_VERSION}-${ARCH}.log" 2>&1
	make install_sw >> "/tmp/${OPENSSL_VERSION}-${ARCH}.log" 2>&1
	# Keep openssl binary for Mac version
	cp "/tmp/${OPENSSL_VERSION}-${ARCH}/bin/openssl" "/tmp/openssl"
	make clean >> "/tmp/${OPENSSL_VERSION}-${ARCH}.log" 2>&1
	popd > /dev/null
}

buildIOS()
{
	ARCH=$1

	pushd . > /dev/null
	cd "${OPENSSL_VERSION}"

	if [[ "${ARCH}" == "i386" || "${ARCH}" == "x86_64" ]]; then
		PLATFORM="iPhoneSimulator"
	else
		PLATFORM="iPhoneOS"
		#sed -ie "s!static volatile sig_atomic_t intr_signal;!static volatile intr_signal;!" "crypto/ui/ui_openssl.c"
	fi

	export $PLATFORM
	export CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
	export CROSS_SDK="${PLATFORM}${IOS_SDK_VERSION}.sdk"
	export BUILD_TOOLS="${DEVELOPER}"
	export CC="${BUILD_TOOLS}/usr/bin/gcc -fembed-bitcode -arch ${ARCH}"

	echo -e "${subbold}Building ${OPENSSL_VERSION} for ${PLATFORM} ${IOS_SDK_VERSION} ${archbold}${ARCH}${dim}"

	if [[ "${ARCH}" == "i386" || "${ARCH}" == "x86_64" ]]; then
		TARGET="darwin-i386-cc"
		if [[ $ARCH == "x86_64" ]]; then
			TARGET="darwin64-x86_64-cc"
		fi
		if [[ "$OPENSSL_VERSION" = "openssl-1.1.1"* ]]; then
			./Configure no-asm ${TARGET} -no-shared --prefix="/tmp/${OPENSSL_VERSION}-iOS-${ARCH}" --openssldir="/tmp/${OPENSSL_VERSION}-iOS-${ARCH}" $CUSTOMCONFIG &> "/tmp/${OPENSSL_VERSION}-iOS-${ARCH}.log"
		else
			./Configure no-asm ${TARGET} -no-shared --openssldir="/tmp/${OPENSSL_VERSION}-iOS-${ARCH}" $CUSTOMCONFIG &> "/tmp/${OPENSSL_VERSION}-iOS-${ARCH}.log"
		fi
	else
		if [[ "$OPENSSL_VERSION" = "openssl-1.1.1"* ]]; then
			# export CC="${BUILD_TOOLS}/usr/bin/gcc -arch ${ARCH}"
			./Configure iphoneos-cross DSO_LDFLAGS=-fembed-bitcode --prefix="/tmp/${OPENSSL_VERSION}-iOS-${ARCH}" -no-shared --openssldir="/tmp/${OPENSSL_VERSION}-iOS-${ARCH}" $CUSTOMCONFIG &> "/tmp/${OPENSSL_VERSION}-iOS-${ARCH}.log"
		else
			./Configure iphoneos-cross -no-shared --openssldir="/tmp/${OPENSSL_VERSION}-iOS-${ARCH}" $CUSTOMCONFIG &> "/tmp/${OPENSSL_VERSION}-iOS-${ARCH}.log"
		fi
	fi
	# add -isysroot to CC=
	if [[ "$OPENSSL_VERSION" = "openssl-1.1.1"* ]]; then
		sed -ie "s!^CFLAGS=!CFLAGS=-isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -miphoneos-version-min=${IOS_MIN_SDK_VERSION} !" "Makefile"
	else
		sed -ie "s!^CFLAG=!CFLAG=-isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -miphoneos-version-min=${IOS_MIN_SDK_VERSION} !" "Makefile"
	fi

	make >> "/tmp/${OPENSSL_VERSION}-iOS-${ARCH}.log" 2>&1
	make install_sw >> "/tmp/${OPENSSL_VERSION}-iOS-${ARCH}.log" 2>&1
	make clean >> "/tmp/${OPENSSL_VERSION}-iOS-${ARCH}.log" 2>&1
	popd > /dev/null
}

buildTVOS()
{
	ARCH=$1

	pushd . > /dev/null
	cd "${OPENSSL_VERSION}"

	if [[ "${ARCH}" == "x86_64" ]]; then
		PLATFORM="AppleTVSimulator"
	else
		PLATFORM="AppleTVOS"
		sed -ie "s!static volatile sig_atomic_t intr_signal;!static volatile intr_signal;!" "crypto/ui/ui_openssl.c"
	fi

	export $PLATFORM
	export CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
	export CROSS_SDK="${PLATFORM}${TVOS_SDK_VERSION}.sdk"
	export BUILD_TOOLS="${DEVELOPER}"
	export CC="${BUILD_TOOLS}/usr/bin/gcc -fembed-bitcode -arch ${ARCH}"
	export LC_CTYPE=C

	echo -e "${subbold}Building ${OPENSSL_VERSION} for ${PLATFORM} ${TVOS_SDK_VERSION} ${archbold}${ARCH}${dim}"

	# Patch apps/speed.c to not use fork() since it's not available on tvOS
	LANG=C sed -i -- 's/define HAVE_FORK 1/define HAVE_FORK 0/' "./apps/speed.c"
	if [[ "$OPENSSL_VERSION" = "openssl-1.1.1"* ]]; then
		LANG=C sed -i -- 's/!defined(OPENSSL_NO_POSIX_IO)/defined(HAVE_FORK)/' "./apps/ocsp.c"
		LANG=C sed -i -- 's/fork()/-1/' "./apps/ocsp.c"
                LANG=C sed -i -- 's/fork()/-1/' "./test/drbgtest.c"
		LANG=C sed -i -- 's/!defined(OPENSSL_NO_ASYNC)/defined(HAVE_FORK)/' "./crypto/async/arch/async_posix.h"
	fi
	
	# Patch Configure to build for tvOS, not iOS
	LANG=C sed -i -- 's/D\_REENTRANT\:iOS/D\_REENTRANT\:tvOS/' "./Configure"
	chmod u+x ./Configure

	if [[ "${ARCH}" == "x86_64" ]]; then
		if [[ "$OPENSSL_VERSION" = "openssl-1.1.1"* ]]; then
			./Configure no-asm darwin64-x86_64-cc -no-shared --prefix="/tmp/${OPENSSL_VERSION}-tvOS-${ARCH}" --openssldir="/tmp/${OPENSSL_VERSION}-tvOS-${ARCH}" $CUSTOMCONFIG &> "/tmp/${OPENSSL_VERSION}-tvOS-${ARCH}.log"
		else
			./Configure no-asm darwin64-x86_64-cc --openssldir="/tmp/${OPENSSL_VERSION}-tvOS-${ARCH}" $CUSTOMCONFIG &> "/tmp/${OPENSSL_VERSION}-tvOS-${ARCH}.log"
		fi
	else
		export CC="${BUILD_TOOLS}/usr/bin/gcc -fembed-bitcode -arch ${ARCH}"
		if [[ "$OPENSSL_VERSION" = "openssl-1.1.1"* ]]; then
			./Configure iphoneos-cross DSO_LDFLAGS=-fembed-bitcode --prefix="/tmp/${OPENSSL_VERSION}-tvOS-${ARCH}" -no-shared --openssldir="/tmp/${OPENSSL_VERSION}-tvOS-${ARCH}" $CUSTOMCONFIG &> "/tmp/${OPENSSL_VERSION}-tvOS-${ARCH}.log"
		else
			./Configure iphoneos-cross --openssldir="/tmp/${OPENSSL_VERSION}-tvOS-${ARCH}" $CUSTOMCONFIG &> "/tmp/${OPENSSL_VERSION}-tvOS-${ARCH}.log"
		fi
	fi
	# add -isysroot to CC=
	if [[ "$OPENSSL_VERSION" = "openssl-1.1.1"* ]]; then
		sed -ie "s!^CFLAGS=!CFLAGS=-isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -mtvos-version-min=${TVOS_MIN_SDK_VERSION} !" "Makefile"
	else
		sed -ie "s!^CFLAG=!CFLAG=-isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -mtvos-version-min=${TVOS_MIN_SDK_VERSION} !" "Makefile"
	fi

	make >> "/tmp/${OPENSSL_VERSION}-tvOS-${ARCH}.log" 2>&1
	make install_sw >> "/tmp/${OPENSSL_VERSION}-tvOS-${ARCH}.log" 2>&1
	make clean >> "/tmp/${OPENSSL_VERSION}-tvOS-${ARCH}.log" 2>&1
	popd > /dev/null
}


echo -e "${bold}Cleaning up${dim}"
rm -rf include/openssl/* lib/*

mkdir -p Mac/lib
mkdir -p iOS/lib
mkdir -p tvOS/lib
mkdir -p Mac/include/openssl/
mkdir -p iOS/include/openssl/
mkdir -p tvOS/include/openssl/

rm -rf "/tmp/${OPENSSL_VERSION}-*"
rm -rf "/tmp/${OPENSSL_VERSION}-*.log"

rm -rf "${OPENSSL_VERSION}"

if [ ! -e ${OPENSSL_VERSION}.tar.gz ]; then
	echo "Downloading ${OPENSSL_VERSION}.tar.gz"
	curl -LO https://www.openssl.org/source/${OPENSSL_VERSION}.tar.gz
else
	echo "Using ${OPENSSL_VERSION}.tar.gz"
fi

if [[ "$OPENSSL_VERSION" = "openssl-1.1.1"* ]]; then
	echo "** Building OpenSSL 1.1.1 **"
else
	if [[ "$OPENSSL_VERSION" = "openssl-1.0."* ]]; then
		echo "** Building OpenSSL 1.0.x ** "
		echo -e "${alert}** WARNING: End of Life Version - Upgrade to 1.1.1 **${dim}"
	else
		echo -e "${alert}** WARNING: This build script has not been tested with $OPENSSL_VERSION **${dim}"
	fi
fi

echo "Unpacking openssl"
tar xfz "${OPENSSL_VERSION}.tar.gz"

if [ "$engine" == "1" ]; then
	echo "+ Activate Static Engine"
	sed -ie 's/\"engine/\"dynamic-engine/' ${OPENSSL_VERSION}/Configurations/15-ios.conf
fi

echo -e "${bold}Building Mac libraries${dim}"
buildMac "x86_64"

echo "  Copying headers and libraries"
cp /tmp/${OPENSSL_VERSION}-x86_64/include/openssl/* Mac/include/openssl/

lipo \
	"/tmp/${OPENSSL_VERSION}-x86_64/lib/libcrypto.a" \
	-create -output Mac/lib/libcrypto.a

lipo \
	"/tmp/${OPENSSL_VERSION}-x86_64/lib/libssl.a" \
	-create -output Mac/lib/libssl.a

echo -e "${bold}Building iOS libraries${dim}"
buildIOS "armv7"
buildIOS "armv7s"
buildIOS "arm64"
buildIOS "arm64e"
buildIOS "i386"
buildIOS "x86_64"

echo "  Copying headers and libraries"
cp /tmp/${OPENSSL_VERSION}-iOS-arm64/include/openssl/* iOS/include/openssl/

lipo \
	"/tmp/${OPENSSL_VERSION}-iOS-armv7/lib/libcrypto.a" \
	"/tmp/${OPENSSL_VERSION}-iOS-armv7s/lib/libcrypto.a" \
	"/tmp/${OPENSSL_VERSION}-iOS-i386/lib/libcrypto.a" \
	"/tmp/${OPENSSL_VERSION}-iOS-arm64/lib/libcrypto.a" \
	"/tmp/${OPENSSL_VERSION}-iOS-arm64e/lib/libcrypto.a" \
	"/tmp/${OPENSSL_VERSION}-iOS-x86_64/lib/libcrypto.a" \
	-create -output iOS/lib/libcrypto.a

lipo \
	"/tmp/${OPENSSL_VERSION}-iOS-armv7/lib/libssl.a" \
	"/tmp/${OPENSSL_VERSION}-iOS-armv7s/lib/libssl.a" \
	"/tmp/${OPENSSL_VERSION}-iOS-i386/lib/libssl.a" \
	"/tmp/${OPENSSL_VERSION}-iOS-arm64/lib/libssl.a" \
	"/tmp/${OPENSSL_VERSION}-iOS-arm64e/lib/libssl.a" \
	"/tmp/${OPENSSL_VERSION}-iOS-x86_64/lib/libssl.a" \
	-create -output iOS/lib/libssl.a


echo -e "${bold}Building tvOS libraries${dim}"
buildTVOS "arm64"
buildTVOS "x86_64"
echo "  Copying headers and libraries"
cp /tmp/${OPENSSL_VERSION}-tvOS-arm64/include/openssl/* tvOS/include/openssl/

lipo \
	"/tmp/${OPENSSL_VERSION}-tvOS-arm64/lib/libcrypto.a" \
	"/tmp/${OPENSSL_VERSION}-tvOS-x86_64/lib/libcrypto.a" \
	-create -output tvOS/lib/libcrypto.a

lipo \
	"/tmp/${OPENSSL_VERSION}-tvOS-arm64/lib/libssl.a" \
	"/tmp/${OPENSSL_VERSION}-tvOS-x86_64/lib/libssl.a" \
	-create -output tvOS/lib/libssl.a

echo -e "${bold}Cleaning up${dim}"
rm -rf /tmp/${OPENSSL_VERSION}-*
rm -rf ${OPENSSL_VERSION}

#reset trap
trap - INT TERM EXIT

echo -e "${normal}Done"
