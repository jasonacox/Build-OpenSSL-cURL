# iOS Test App

This is a test app for iOS using the curl, openssl and nghttp2 libraries.

## Build Instructions

Build the libraries with Mac Catalyst support:

```bash
# Build Mac Catalyst Support for iOS Target 15.0
./build.sh -m -u 15.0
```

Load and build the project using Xcode. Example lib binaries (xcframework)and header files are included but will be replaced when you run the build script.

## Screenshot

![iOS Test App](screenshot.png)
