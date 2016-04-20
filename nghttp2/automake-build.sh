#!/bin/bash
# Automake & Autoconf on Mac
#
# Only use this if you do not have Automakef installed already
# If you have BREW installed, we will use that instead of building these.
# 
usage ()
{
        echo "usage: $0"
        exit 127
}
if [ "$1" == "-h" ]; then
        usage
fi

# change to update versions if build is required
AUTOCONF="autoconf-2.69"
AUTOMAKE="automake-1.15"

#
# Check to see if automake and autoconf are already installed
if (type "automake" > /dev/null) && (type "autoreconf" > /dev/null); then
	echo "Automake tools are already installed - exiting"
	exit
fi

# Check to see if Brew is installed
if ! type "brew" > /dev/null; then
	echo "brew not installed - attempting manual builds"
	# AUTOCONF
	curl -OL http://ftpmirror.gnu.org/autoconf/${AUTOCONF}.tar.gz
	tar -xzf ${AUTOCONF}.tar.gz 
	cd ${AUTOCONF}
	echo "building..."
	#./configure && make && sudo make install
	cd ..
	 
	curl -OL http://ftpmirror.gnu.org/automake/${AUTOMAKE}.tar.gz
	tar -xzf ${AUTOMAKE}.tar.gz
	cd ${AUTOMAKE}
	echo "building..."
	#./configure && make && sudo make install
	cd ..
	#
else
	echo "brew installed - using to install automake"
	brew install automake
fi

# Check to see if installation workedjj
if (type "automake" > /dev/null) && (type "autoreconf" > /dev/null); then
	echo "SUCCESS: Automake tools installed"
	exit
else
	echo "ERROR: Automake tools failed to install"
	exit
fi
 
#curl -OL http://ftpmirror.gnu.org/libtool/libtool-2.4.2.tar.gz
#tar -xzf libtool-2.4.2.tar.gz
#cd libtool-2.4.2
#./configure && make && sudo make install
#cd ..
