# tvOS Test App

This is a test app for tvOS using the curl, openssl and nghttp2 libraries.

## Screenshots

tvOS Test Build

![Image](https://github.com/user-attachments/assets/fd0b1e2b-6f2c-4295-853a-574dc8533461)

## Build Instructions

Build the libraries with tvOS support:

```bash
# Standard Build
./build.sh

# Option: Build only tvOS
./build.sh -p tvos
```

Load and build the project using Xcode. Example lib binaries (xcframework) and header files are included but will be replaced when you run the build script.

## New Project Setup Details

If you are setting up a new Xcode project, there are few things you will need to set up. These are all set up for you already in the xcodeproj file:

* You will also need to add the xcframework files (libs) and header files (include). You will also need to add libz.tbd to the Xcode project ("General"). 
 <img width="495" alt="Image" src="https://github.com/user-attachments/assets/a1f194e4-2947-48e9-aa57-01458a79f623" />

