#!/bin/bash
#
# This script downlaods and builds the Mac, Catalyst,iOS and tvOS openSSL libraries with Bitcode enabled
#
# Author: Jason Cox, @jasonacox https://github.com/jasonacox/Build-OpenSSL-cURL
# Date: 2020-Aug-15

set -e

# Default Version
VERSION="openssl-3.0.9"

# Phase 1 - Mac, Catalyst and tvOS
OPENSSL_VERSION="$VERSION" ./openssl-build-phase1.sh "$@"

# Phase 2 - iOS
OPENSSL_VERSION="$VERSION" ./openssl-build-phase2.sh "$@"

# Done
echo -e "${normal}Done"
