# iOS Test App

This is a test app for iOS using the curl, openssl and nghttp2 libraries.

## Build Instructions

Build the libraries with Mac Catalyst support:

```bash
# Build Mac Catalyst Support for iOS Target 15.0
./build.sh -m -u 15.0
```

Load and build the project using Xcode. Example lib binaries (xcframework)and header files are included but will be replaced when you run the build script.

## Screenshots

iOS Test Build

<img width="400" alt="image" src="https://github.com/jasonacox/Build-OpenSSL-cURL/assets/836718/6de13ab3-b7fe-4017-bf6d-9cbde131c098">
<img width="400" alt="image" src="https://github.com/jasonacox/Build-OpenSSL-cURL/assets/836718/66806f0c-0915-4742-b71c-b683300082ae">

Mac Catalyst Build

<img width="400" alt="image" src="https://github.com/jasonacox/Build-OpenSSL-cURL/assets/836718/c5ee7356-ea03-4091-a362-c79b123829fd">
<img width="400" alt="image" src="https://github.com/jasonacox/Build-OpenSSL-cURL/assets/836718/0369f35c-7c80-4cbe-92fb-c6008b115fa9">
