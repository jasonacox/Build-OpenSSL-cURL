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

usage ()
{
	echo
	echo -e "${bold}Usage:${normal}"
	echo
	echo -e "  ${subbold}$0${normal} [-o ${dim}<openssl phase>${normal}] [-n] [-c] [-d] [-h]"
	echo
	echo "         -o   Upload openssl for phase (1 or 2)"
	echo "         -n   Upload nghttp2"
	echo "         -c   Upload libcurl"
	echo "         -d   Download everything"
	echo "         -h   show usage"
	echo
	trap - INT TERM EXIT
	exit 127
}

engine=0

while getopts "o:ncdh\?" o; do
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
			tar -zxvf *.tgz
			;;
		*)
			usage
			;;
	esac
done
shift $((OPTIND-1))



