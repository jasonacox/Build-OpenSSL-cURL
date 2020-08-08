# Build-OpenSSL-cURL Binaries 

The `build.sh` script stores the builds in this archive directory. The directory names are based on the version of the releases of OpenSSL, nghttp2 and libcurl and includes the libraries for MacOS, Mac Catalyst, iOS and tvOS.  

## Build Your Own or Use These
See the `build.sh` script in parent directory.

## Download Compressed Archives

Previous builds can be downloaded form the Github releases for this project: https://github.com/jasonacox/Build-OpenSSL-cURL/releases

## Archive

This directory contains the curl and openssl headers (in the `include` folder), the various *.a libraries built along with a MacOS binary for `curl` and `openssl`.

	archive
	   |
	   |___libcurl-7.50.1-openssl-1.0.1t-nghttp2-1.14.0
	     |
	     |____bin/
	     |  |____openssl*
	     |  |____curl*
	     |
	     |____lib/
		 |  |____Catalyst/
	     |  |____iOS/
	     |  |____MacOS/
	     |  |____tvOS/
	     |
	     |____include/
	        |____openssl/
	        |____curl/
 
## License

The MIT License is used for this project.  See LICENSE file.



