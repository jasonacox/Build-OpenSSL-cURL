#!/bin/bash

# This script builds openssl+libcurl libraries for MacOS, iOS and tvOS
#
# Jason Cox, @jasonacox
#   https://github.com/jasonacox/Build-OpenSSL-cURL
#

# Ensure we stop if build failure occurs
set -e

################################################
# EDIT this section to Select Default Versions #
################################################

#OPENSSL="1.1.1u"	# https://www.openssl.org/source/ 
OPENSSL="3.0.13"	# https://www.openssl.org/source/ 
LIBCURL="8.7.1"		# https://curl.haxx.se/download.html
NGHTTP2="1.60.0"	# https://nghttp2.org/

################################################

# Build Machine
BUILD_MACHINE=`uname -m`
BUILD_CMD=$*

# Set minimum OS versions for target
MACOS_X86_64_VERSION=""			# Empty = use host version
MACOS_ARM64_VERSION=""			# Min supported is MacOS 11.0 Big Sur
CATALYST_IOS="15.0"			# Min supported is iOS 15.0 for Mac Catalyst
IOS_MIN_SDK_VERSION="8.0"
TVOS_MIN_SDK_VERSION="9.0"

# Semantic Version Comparison
version_lte() {
    [  "$1" = "`echo -e "$1\n$2" | sort -V | head -n1`" ]
}

if [ -z "${MACOS_X86_64_VERSION}" ]; then
	MACOS_X86_64_VERSION=$(sw_vers -productVersion)
fi
if [ -z "${MACOS_ARM64_VERSION}" ]; then
	MACOS_ARM64_VERSION=$(sw_vers -productVersion)
fi
if version_lte $MACOS_ARM64_VERSION 11.0; then
        MACOS_ARM64_VERSION="11.0"      # Min support for Apple Silicon is 11.0
fi

# Global flags
engine=""
buildnghttp2="-n"
disablebitcode=""
colorflag=""
catalyst=""
sslv3=""

# Formatting
default="\033[39m"
white="\033[97m"
green="\033[32m"
red="\033[91m"
yellow="\033[33m"

bold="\033[0m${white}\033[1m"
subbold="\033[0m${green}"
normal="${white}\033[0m"
dim="\033[0m${white}\033[2m"
alert="\033[0m${red}\033[1m"
alertdim="\033[0m${red}\033[2m"

# Show Usage
usage ()
{
    echo
	echo -e "${bold}Usage:${normal}"
	echo
	echo -e "  ${subbold}$0${normal} [-o ${dim}<OpenSSL version>${normal}] [-c ${dim}<curl version>${normal}] [-n ${dim}<nghttp2 version>${normal}] [-d] [-e] [-3] [-x] [-h] [...]"
	echo
	echo "         -o <version>   Build OpenSSL version (default $OPENSSL)"
	echo "         -c <version>   Build curl version (default $LIBCURL)"
	echo "         -n <version>   Build nghttp2 version (default $NGHTTP2)"
	echo "         -d             Compile without HTTP2 support"
	echo "         -e             Compile with OpenSSL engine support"
	echo "         -b             Compile without bitcode"
	echo "         -m             Compile Mac Catalyst library"
	echo "         -u <version>   Mac Catalyst iOS min target version (default $CATALYST_IOS)"
	echo "         -3             Compile with SSLv3"
	echo "         -s <version>   iOS min target version (default $IOS_MIN_SDK_VERSION)"
	echo "         -t <version>   tvOS min target version (default $TVOS_MIN_SDK_VERSION)"
	echo "         -i <version>   macOS 86_64 min target version (default $MACOS_X86_64_VERSION)"
	echo "         -a <version>   macOS arm64 min target version (default $MACOS_ARM64_VERSION)"
	echo "         -x             No color output"
	echo "         -h             Show usage"
	echo
    exit 127
}

# Process command line arguments
while getopts "o:c:n:u:s:t:i:a:debm3xh\?" o; do
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
			buildnghttp2=""
			;;
		e)
			engine="-e"
			;;
		b)
			disablebitcode="-b"
			;;
		m)
       		catalyst="-m"
			;;
		u)
			catalyst="-m -u ${OPTARG}"
			CATALYST_IOS="${OPTARG}"
			;;
		3)
       		echo "WARNING: SSLv3 is requested. SSLv3 is not secure and has been deprecated."
			echo "If you proceed, builds may fail as SSLv3 is no longer supported by curl."
			read -p "Do you want to continue (y/N)? " choice
			case "$choice" in 
				y|Y ) echo "Continuing with SSLv3 build"; echo "";;
				* ) echo "Exiting"; exit 1;;
			esac
			sslv3="-3"
			;;
		s)
			IOS_MIN_SDK_VERSION="${OPTARG}"
			;;
		t)
			TVOS_MIN_SDK_VERSION="${OPTARG}"
			;;
		i)
			MACOS_X86_64_VERSION="${OPTARG}"
			;;
		a)
			MACOS_ARM64_VERSION="${OPTARG}"
			;;
		x)
			bold=""
			subbold=""
			normal=""
			dim=""
			alert=""
			alertdim=""
			colorflag="-x"
			;;
		*)
			usage
			;;
    esac
done
shift $((OPTIND-1))

# Set OS min versions
OSARGS="-s ${IOS_MIN_SDK_VERSION} -t ${TVOS_MIN_SDK_VERSION} -i ${MACOS_X86_64_VERSION} -a ${MACOS_ARM64_VERSION}"

## Welcome
echo -e "${bold}Build-OpenSSL-cURL${dim}"
if [ "$catalyst" != "" ]; then
	echo "This script builds OpenSSL, nghttp2 and libcurl for MacOS, Catalyst, iOS and tvOS devices."
else
	echo "This script builds OpenSSL, nghttp2 and libcurl for MacOS, iOS and tvOS devices."
fi
echo "Targets: x86_64, armv7, armv7s, arm64 and arm64e"

## Start Counter
START=$(date +%s)

# Starting with OpenSSL 3.0 force nobitcode
if [[ "$OPENSSL" = "3.0"* ]]; then
	disablebitcode="-b"
fi

## OpenSSL Build
echo
cd openssl
echo -e "${bold}Building OpenSSL${normal}"
./openssl-build.sh -v "$OPENSSL" $engine $colorflag $catalyst $sslv3 $OSARGS
cd ..

## Nghttp2 Build
if [ "$buildnghttp2" == "" ]; then
	NGHTTP2="NONE"
else
	echo
	echo -e "${bold}Building nghttp2 for HTTP2 support${normal}"
	cd nghttp2
	./nghttp2-build.sh -v "$NGHTTP2" $colorflag $catalyst $OSARGS
	cd ..
fi

## Curl Build
echo
echo -e "${bold}Building Curl${normal}"
cd curl
./libcurl-build.sh -v "$LIBCURL" $disablebitcode $colorflag $buildnghttp2 $catalyst $sslv3 $OSARGS
cd ..

## Archive Libraries and Clean Up
echo
echo -e "${bold}Libraries...${normal}"
echo
echo -e "${subbold}openssl${normal} [${dim}$OPENSSL${normal}]${dim}"
xcrun -sdk iphoneos lipo -info openssl/*/lib/*.a
if [ "$buildnghttp2" != "" ]; then
	echo
	echo -e "${subbold}nghttp2 (rename to libnghttp2.a)${normal} [${dim}$NGHTTP2${normal}]${dim}"
	xcrun -sdk iphoneos lipo -info nghttp2/lib/*.a
fi
echo
echo -e "${subbold}libcurl (rename to libcurl.a)${normal} [${dim}$LIBCURL${normal}]${dim}"
xcrun -sdk iphoneos lipo -info curl/lib/*.a

EXAMPLE="example/iOS Test App"
ARCHIVE="archive/libcurl-$LIBCURL-openssl-$OPENSSL-nghttp2-$NGHTTP2"

echo
echo -e "${bold}Creating archive with XCFrameworks for release v$LIBCURL...${dim}"
echo "  See $ARCHIVE"
rm -rf "$ARCHIVE"
mkdir -p "$ARCHIVE"
mkdir -p "$ARCHIVE/include/openssl"
mkdir -p "$ARCHIVE/include/curl"
mkdir -p "$ARCHIVE/lib/iOS"
mkdir -p "$ARCHIVE/lib/iOS-simulator"
mkdir -p "$ARCHIVE/lib/iOS-fat"
mkdir -p "$ARCHIVE/lib/MacOS"
mkdir -p "$ARCHIVE/lib/tvOS"
mkdir -p "$ARCHIVE/lib/tvOS-simulator"
if [ "$catalyst" != "" ]; then
	mkdir -p "$ARCHIVE/lib/Catalyst"
fi
mkdir -p "$ARCHIVE/bin"
mkdir -p "$ARCHIVE/framework"
mkdir -p "$ARCHIVE/xcframework"

# libraries for libcurl, libcrypto and libssl
cp curl/lib/libcurl_iOS.a $ARCHIVE/lib/iOS/libcurl.a
cp curl/lib/libcurl_iOS-simulator.a $ARCHIVE/lib/iOS-simulator/libcurl.a
cp curl/lib/libcurl_iOS-fat.a $ARCHIVE/lib/iOS-fat/libcurl.a
cp curl/lib/libcurl_tvOS.a $ARCHIVE/lib/tvOS/libcurl.a
cp curl/lib/libcurl_tvOS-simulator.a $ARCHIVE/lib/tvOS-simulator/libcurl.a
cp curl/lib/libcurl_Mac.a $ARCHIVE/lib/MacOS/libcurl.a

cp openssl/iOS/lib/libcrypto.a $ARCHIVE/lib/iOS/libcrypto.a
cp openssl/iOS-simulator/lib/libcrypto.a $ARCHIVE/lib/iOS-simulator/libcrypto.a
cp openssl/iOS-fat/lib/libcrypto.a $ARCHIVE/lib/iOS-fat/libcrypto.a
cp openssl/tvOS/lib/libcrypto.a $ARCHIVE/lib/tvOS/libcrypto.a
cp openssl/tvOS-simulator/lib/libcrypto.a $ARCHIVE/lib/tvOS-simulator/libcrypto.a
cp openssl/Mac/lib/libcrypto.a $ARCHIVE/lib/MacOS/libcrypto.a

cp openssl/iOS/lib/libssl.a $ARCHIVE/lib/iOS/libssl.a
cp openssl/iOS-simulator/lib/libssl.a $ARCHIVE/lib/iOS-simulator/libssl.a
cp openssl/iOS-fat/lib/libssl.a $ARCHIVE/lib/iOS-fat/libssl.a
cp openssl/tvOS/lib/libssl.a $ARCHIVE/lib/tvOS/libssl.a
cp openssl/tvOS-simulator/lib/libssl.a $ARCHIVE/lib/tvOS-simulator/libssl.a
cp openssl/Mac/lib/libssl.a $ARCHIVE/lib/MacOS/libssl.a

if [ "$catalyst" != "" ]; then
	# Add catalyst libraries
	cp curl/lib/libcurl_Catalyst.a $ARCHIVE/lib/Catalyst/libcurl.a
	cp openssl/Catalyst/lib/libcrypto.a $ARCHIVE/lib/Catalyst/libcrypto.a
	cp openssl/Catalyst/lib/libssl.a $ARCHIVE/lib/Catalyst/libssl.a

	# Build XCFrameworks with Catalyst library
	xcodebuild -create-xcframework \
		-library $ARCHIVE/lib/iOS/libcurl.a \
        -headers curl/include \
		-library $ARCHIVE/lib/iOS-simulator/libcurl.a \
        -headers curl/include \
		-library $ARCHIVE/lib/tvOS/libcurl.a \
        -headers curl/include \
		-library $ARCHIVE/lib/tvOS-simulator/libcurl.a \
        -headers curl/include \
		-library $ARCHIVE/lib/Catalyst/libcurl.a \
        -headers curl/include \
        -library $ARCHIVE/lib/MacOS/libcurl.a \
        -headers curl/include \
		-output $ARCHIVE/xcframework/libcurl.xcframework
	xcodebuild -create-xcframework \
		-library $ARCHIVE/lib/iOS/libcrypto.a \
        -headers openssl/iOS/include \
		-library $ARCHIVE/lib/iOS-simulator/libcrypto.a \
        -headers openssl/iOS-simulator/include \
		-library $ARCHIVE/lib/tvOS/libcrypto.a \
        -headers openssl/tvOS/include \
		-library $ARCHIVE/lib/tvOS-simulator/libcrypto.a \
        -headers openssl/tvOS-simulator/include \
		-library $ARCHIVE/lib/Catalyst/libcrypto.a \
        -headers openssl/Mac/include \
        -library $ARCHIVE/lib/MacOS/libcrypto.a \
        -headers openssl/Mac/include \
		-output $ARCHIVE/xcframework/libcrypto.xcframework
	xcodebuild -create-xcframework \
		-library $ARCHIVE/lib/iOS/libssl.a \
		-library $ARCHIVE/lib/iOS-simulator/libssl.a \
		-library $ARCHIVE/lib/tvOS/libssl.a \
		-library $ARCHIVE/lib/tvOS-simulator/libssl.a \
		-library $ARCHIVE/lib/Catalyst/libssl.a \
        -library $ARCHIVE/lib/MacOS/libssl.a \
		-output $ARCHIVE/xcframework/libssl.xcframework
else
	# Build XCFrameworks
	xcodebuild -create-xcframework \
		-library $ARCHIVE/lib/iOS/libcurl.a \
        -headers curl/include \
		-library $ARCHIVE/lib/iOS-simulator/libcurl.a \
        -headers curl/include \
		-library $ARCHIVE/lib/tvOS/libcurl.a \
        -headers curl/include \
		-library $ARCHIVE/lib/tvOS-simulator/libcurl.a \
        -headers curl/include \
        -library $ARCHIVE/lib/MacOS/libcurl.a \
        -headers curl/include \
		-output $ARCHIVE/xcframework/libcurl.xcframework
	xcodebuild -create-xcframework \
		-library $ARCHIVE/lib/iOS/libcrypto.a \
        -headers openssl/iOS/include \
		-library $ARCHIVE/lib/iOS-simulator/libcrypto.a \
        -headers openssl/iOS-simulator/include \
		-library $ARCHIVE/lib/tvOS/libcrypto.a \
        -headers openssl/tvOS/include \
		-library $ARCHIVE/lib/tvOS-simulator/libcrypto.a \
        -headers openssl/tvOS-simulator/include \
        -library $ARCHIVE/lib/MacOS/libcrypto.a \
        -headers openssl/Mac/include \
		-output $ARCHIVE/xcframework/libcrypto.xcframework
	xcodebuild -create-xcframework \
		-library $ARCHIVE/lib/iOS/libssl.a \
		-library $ARCHIVE/lib/iOS-simulator/libssl.a \
		-library $ARCHIVE/lib/tvOS/libssl.a \
		-library $ARCHIVE/lib/tvOS-simulator/libssl.a \
        -library $ARCHIVE/lib/MacOS/libssl.a \
		-output $ARCHIVE/xcframework/libssl.xcframework
fi

cp openssl/*.a $ARCHIVE/framework

# libraries for nghttp2
if [ "$buildnghttp2" != "" ]; then
    # nghttp2 libraries
	cp nghttp2/lib/libnghttp2_iOS.a $ARCHIVE/lib/iOS/libnghttp2.a
	cp nghttp2/lib/libnghttp2_iOS-simulator.a $ARCHIVE/lib/iOS-simulator/libnghttp2.a
	cp nghttp2/lib/libnghttp2_iOS-fat.a $ARCHIVE/lib/iOS-fat/libnghttp2.a
	cp nghttp2/lib/libnghttp2_tvOS.a $ARCHIVE/lib/tvOS/libnghttp2.a
	cp nghttp2/lib/libnghttp2_tvOS-simulator.a $ARCHIVE/lib/tvOS-simulator/libnghttp2.a
	cp nghttp2/lib/libnghttp2_Mac.a $ARCHIVE/lib/MacOS/libnghttp2.a
	if [ "$catalyst" != "" ]; then
		cp nghttp2/lib/libnghttp2_Catalyst.a $ARCHIVE/lib/Catalyst/libnghttp2.a
		xcodebuild -create-xcframework \
			-library $ARCHIVE/lib/iOS/libnghttp2.a \
			-library $ARCHIVE/lib/iOS-simulator/libnghttp2.a \
			-library $ARCHIVE/lib/tvOS/libnghttp2.a \
			-library $ARCHIVE/lib/tvOS-simulator/libnghttp2.a \
			-library $ARCHIVE/lib/Catalyst/libnghttp2.a \
            -library $ARCHIVE/lib/MacOS/libnghttp2.a \
			-output $ARCHIVE/xcframework/libnghttp2.xcframework
	else
		xcodebuild -create-xcframework \
			-library $ARCHIVE/lib/iOS/libnghttp2.a \
			-library $ARCHIVE/lib/iOS-simulator/libnghttp2.a \
			-library $ARCHIVE/lib/tvOS/libnghttp2.a \
			-library $ARCHIVE/lib/tvOS-simulator/libnghttp2.a \
            -library $ARCHIVE/lib/MacOS/libnghttp2.a \
			-output $ARCHIVE/xcframework/libnghttp2.xcframework
	fi
fi

# archive header files
cp openssl/iOS/include/openssl/* "$ARCHIVE/include/openssl"
cp curl/include/curl/* "$ARCHIVE/include/curl"

# grab root certs
curl -sL https://curl.se/ca/cacert.pem > $ARCHIVE/cacert.pem

# create README for archive
sed -e "s/ZZZCMDS/$BUILD_CMD/g" -e "s/ZZZLIBCURL/$LIBCURL/g" -e "s/ZZZOPENSSL/$OPENSSL/g" -e "s/ZZZNGHTTP2/$NGHTTP2/g" archive/release-template.md > $ARCHIVE/README.md
echo

# EXAMPLE App - update test app with latest includes and XCFrameworks
echo -e "${bold}Copying libraries to Test App ...${dim}"
echo "  See $EXAMPLE"
mkdir -p "$EXAMPLE/libs"
mkdir -p "$EXAMPLE/include"
# Includes
cp openssl/iOS-fat/include/openssl/* "$EXAMPLE/include/openssl/"
cp curl/include/curl/* "$EXAMPLE/include/curl/"
cp $ARCHIVE/cacert.pem "$EXAMPLE/iOS Test App/cacert.pem"
# XCFrameworks
cp -R $ARCHIVE/xcframework/libcrypto.xcframework "$EXAMPLE/libs/"
cp -R $ARCHIVE/xcframework/libssl.xcframework "$EXAMPLE/libs/"
cp -R $ARCHIVE/xcframework/libcurl.xcframework "$EXAMPLE/libs/"
if [ "$buildnghttp2" != "" ]; then
	#cp nghttp2/lib/libnghttp2_iOS-fat.a "$EXAMPLE/libs/libnghttp2.a"
	cp -R $ARCHIVE/xcframework/libnghttp2.xcframework "$EXAMPLE/libs/"
fi

echo
# create universal Mac binaries and run test
echo -e "${bold}Archiving Mac binaries for curl and openssl...${dim}"
echo "  See $ARCHIVE/bin"
lipo -create -output $ARCHIVE/bin/curl /tmp/curl-x86_64 /tmp/curl-arm64
mv /tmp/curl-* $ARCHIVE/bin
lipo -create -output $ARCHIVE/bin/openssl /tmp/openssl-x86_64 /tmp/openssl-arm64
mv /tmp/openssl-* $ARCHIVE/bin
echo
echo -e "${bold}Testing Universal Mac binaries for ${BUILD_MACHINE}...${dim}"
echo -e "  ${bold}cURL${dim}"
file $ARCHIVE/bin/curl
$ARCHIVE/bin/curl -V
echo -e "  ${bold}OpenSSL${dim}"
file $ARCHIVE/bin/openssl
$ARCHIVE/bin/openssl version

## Done - Display Build Duration
echo
echo -e "${bold}Build Complete${dim}"
date "+  %c - End"
END=$(date +%s)
secs=$(echo "$END - $START" | bc)
printf '  Duration %02dh:%02dm:%02ds\n' $(($secs/3600)) $(($secs%3600/60)) $(($secs%60))
echo -e "${normal}"

rm -f $NOHTTP2
