#!/bin/bash
echo "Cleaning Build-OpenSSL-cURL"
rm -fr curl/curl-* curl/include curl/lib openssl/openssl-1* openssl/openssl-3* openssl/openssl-ios* openssl/Mac openssl/iOS* openssl/tvOS* openssl/Catalyst nghttp2/nghttp2-1* nghttp2/Mac nghttp2/iOS* nghttp2/tvOS* nghttp2/lib nghttp2/Catalyst example/iOS\ Test\ App/build/* *.tgz *.pkg nghttp2/pkg-config* /tmp/curl /tmp/openssl /tmp/pkg_config
