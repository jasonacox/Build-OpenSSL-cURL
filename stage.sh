#!/bin/bash
#
# Sync Builds to S3 for next stage
#
# Set AWS credentials in envrionment settings
#
# export AWS_ACCESS_KEY_ID=""
# export AWS_SECRET_ACCESS_KEY=""

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

OPENSSL_PHASE="1"

EXAMPLE="example/iOS Test App"

usage ()
{
	echo
	echo -e "${bold}Usage:${normal}"
	echo
	echo -e "  ${subbold}$0${normal} [-o ${dim}<openssl phase>${normal}] [-n] [-c] [-d] [-t] [-h]"
	echo
	echo "         -o   Upload openssl for phase (1 or 2)"
	echo "         -n   Upload nghttp2"
	echo "         -c   Upload libcurl"
	echo "         -d   Download openssl and nghttp2"
	echo "         -u   Upload everything"
	echo "         -t   Download everything and build iOS Test App"
	echo "         -h   show usage"
	echo
	trap - INT TERM EXIT
	exit 127
}

engine=0

while getopts "o:ncduth\?" o; do
	case "${o}" in
		o)
			# archive openssl binaries
			tar -zcvf "openssl-$OPTARG.tgz" openssl/Mac openssl/Catalyst openssl/iOS* openssl/tvOS 
			aws s3 cp "openssl-$OPTARG.tgz" s3://jasonacox.com.travis-build-stage-storage/
			aws s3 ls jasonacox.com.travis-build-stage-storage
			;;
		n)
			# archive nghttp2 binaries
			tar -zcvf "nghttp2.tgz" nghttp2/Catalyst nghttp2/iOS* nghttp2/tvOS nghttp2/lib 
			aws s3 cp "nghttp2.tgz" s3://jasonacox.com.travis-build-stage-storage/
			aws s3 ls jasonacox.com.travis-build-stage-storage
			;;
		c)
			# archive libcurl binaries
			tar -zcvf "curl.tgz" curl/lib curl/include
			aws s3 cp "curl.tgz" s3://jasonacox.com.travis-build-stage-storage/
			aws s3 ls jasonacox.com.travis-build-stage-storage
			;;	
		d)
			# download openssl and nghttp2 binaries
			aws s3 cp s3://jasonacox.com.travis-build-stage-storage/openssl-1.tgz .
			aws s3 cp s3://jasonacox.com.travis-build-stage-storage/openssl-2.tgz .
			aws s3 cp s3://jasonacox.com.travis-build-stage-storage/nghttp2.tgz .
			tar -zxf openssl-1.tgz
			tar -zxf openssl-2.tgz
			tar -zxf nghttp2.tgz
			;;
		u)
			# upload libcurl
			echo "Uploading libcurl libraries..."
			tar -zcf "curl.tgz" curl/lib curl/include
        	aws s3 cp "curl.tgz" s3://jasonacox.com.travis-build-stage-storage/
        	aws s3 ls jasonacox.com.travis-build-stage-storage
			;;
		t)
			# download and test binaries with a iOS Test App
			echo "Fetching libcurl, openssl and nghttp2 libraries..."
			aws s3 cp s3://jasonacox.com.travis-build-stage-storage/curl.tgz .
			aws s3 cp s3://jasonacox.com.travis-build-stage-storage/openssl-1.tgz .
			aws s3 cp s3://jasonacox.com.travis-build-stage-storage/openssl-2.tgz .
			aws s3 cp s3://jasonacox.com.travis-build-stage-storage/nghttp2.tgz .
			tar -zxf openssl-1.tgz
			tar -zxf openssl-2.tgz
			tar -zxf nghttp2.tgz
			tar -zxf curl.tgz
			echo "Fetching root certs..."
			curl -s https://curl.haxx.se/ca/cacert.pem > "$EXAMPLE/cacert.pem"
			echo "Copying libraries to Test App ..."
			mkdir -p "$EXAMPLE/libs"
			cp openssl/iOS-fat/lib/libcrypto.a "$EXAMPLE/libs/libcrypto.a"
			cp openssl/iOS-fat/lib/libssl.a "$EXAMPLE/libs/libssl.a"
			cp openssl/iOS-fat/include/openssl/* "$EXAMPLE/include/openssl/"
			cp curl/include/curl/* "$EXAMPLE/include/curl/"
			cp curl/lib/libcurl_iOS-fat.a "$EXAMPLE/libs/libcurl.a"
			cp nghttp2/lib/libnghttp2_iOS-fat.a "$EXAMPLE/libs/libnghttp2.a"
			echo "Building iOS Test App..."
			xcodebuild clean -project "$EXAMPLE/iOS Test App.xcodeproj"
			xcodebuild build -project "$EXAMPLE/iOS Test App.xcodeproj" -sdk iphonesimulator ONLY_ACTIVE_ARCH=NO
			;;
		*)
			usage
			;;
	esac
done
shift $((OPTIND-1))



