#!/bin/bash 
# Script to prepare the latest build for distribution

# Get the latest build from the build.sh script
OPENSSL=$(grep -oE '^OPENSSL="[^"]+"' build.sh | sed 's/^OPENSSL="\(.*\)"/\1/')
LIBCURL=$(grep -oE '^LIBCURL="[^"]+"' build.sh | sed 's/^LIBCURL="\(.*\)"/\1/')
NGHTTP2=$(grep -oE '^NGHTTP2="[^"]+"' build.sh | sed 's/^NGHTTP2="\(.*\)"/\1/')

# Archive path
BUILD_PATH=archive/libcurl-$LIBCURL-openssl-$OPENSSL-nghttp2-$NGHTTP2

# Check if the path exists
if [ ! -d $BUILD_PATH ]; then
    echo "The path $BUILD_PATH does not exist, run the build.sh script first"
    exit 1
fi

# Inform the user
echo "Latest build is: OpenSSL $OPENSSL, libcurl $LIBCURL, nghttp2 $NGHTTP2"
echo "  Latest build in $BUILD_PATH"
echo ""

# Tar the build
echo "  Creating archive libcurl-$LIBCURL-openssl-$OPENSSL-nghttp2-$NGHTTP2.tgz ..."
cd archive
tar -czf libcurl-$LIBCURL-openssl-$OPENSSL-nghttp2-$NGHTTP2.tgz libcurl-$LIBCURL-openssl-$OPENSSL-nghttp2-$NGHTTP2

# Load the README into the clipboard
cat libcurl-$LIBCURL-openssl-$OPENSSL-nghttp2-$NGHTTP2/README.md | pbcopy

# Notify the user
echo "  Archive created: libcurl-$LIBCURL-openssl-$OPENSSL-nghttp2-$NGHTTP2.tgz"
echo "  README.md loaded into the clipboard"
echo "  Opening the archive folder..."

# Open the archive folder in Finder for upload
open .
