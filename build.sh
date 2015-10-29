#!/bin/bash

echo "Building OpenSSL"
cd openssl
./openssl-build.sh
cd ..

echo
echo "Building Curl"
cd curl
./libcurl-build.sh
cd ..

echo 
echo "Libraries..."
xcrun -sdk iphoneos lipo -info openssl/*/lib/*.a
xcrun -sdk iphoneos lipo -info curl/lib/*.a
