# iOS Test App

This is a test app for iOS using the curl, openssl and nghttp2 libraries.

## Build Instructions

The `libs` and `include` folders will be created during the build. These are required to build and run the Test application in Xcode. Build the libraries with this command:

```bash
# Build Mac Catalyst Support for iOS Target 15.0
./build.sh -m -u 15.0

# Minimum build support
./build.sh -p ios
```

Load and build the project using Xcode. Example lib binaries (xcframework)and header files are included but will be replaced when you run the build script.

## Screenshots

iOS Test Build

<img width="400" alt="image" src="https://github.com/jasonacox/Build-OpenSSL-cURL/assets/836718/6de13ab3-b7fe-4017-bf6d-9cbde131c098">
<img width="400" alt="image" src="https://github.com/jasonacox/Build-OpenSSL-cURL/assets/836718/66806f0c-0915-4742-b71c-b683300082ae">

Mac Catalyst Build

<img width="400" alt="image" src="https://github.com/jasonacox/Build-OpenSSL-cURL/assets/836718/c5ee7356-ea03-4091-a362-c79b123829fd">
<img width="400" alt="image" src="https://github.com/jasonacox/Build-OpenSSL-cURL/assets/836718/0369f35c-7c80-4cbe-92fb-c6008b115fa9">


## New Project Setup Details

If you are setting up a new Xcode project, there are few things you will need to set up. These are all set up for you already in the xcodeproj file:

* You will also need to add the xcframework files (libs) and header files (include). You will also need to add libz.tbd to the Xcode project ("General"). 
 <img width="495" alt="Image" src="https://github.com/user-attachments/assets/a1f194e4-2947-48e9-aa57-01458a79f623" />

