#!/bin/bash

# Copyright (c) 2022 Alex313031.

YEL='\033[1;33m' # Yellow
CYA='\033[1;96m' # Cyan
RED='\033[1;31m' # Red
GRE='\033[1;32m' # Green
c0='\033[0m' # Reset Text
bold='\033[1m' # Bold Text
underline='\033[4m' # Underline Text

# Error handling
yell() { echo "$0: $*" >&2; }
die() { yell "$*"; exit 111; }
try() { "$@" || die "${RED}Failed $*"; }

# --help
displayHelp () {
	printf "\n" &&
	printf "${bold}${GRE}Script to build Geany-ng on Linux.${c0}\n" &&
	printf "${bold}${YEL}Use the --clean flag to run \`make clean\` & \`make distclean\`.${c0}\n" &&
	printf "${bold}${YEL}Use the --debug flag to make a debug build.${c0}\n" &&
	printf "${bold}${YEL}Use the --help flag to show this help.${c0}\n" &&
	printf "\n"
}
case $1 in
	--help) displayHelp; exit 0;;
esac

# Clean artifacts
makeClean () {
	printf "\n" &&
	printf "${YEL}Running \`make clean\` and \`make distclean\`...\n" &&
	printf "${CYA}\n" &&
	make clean && make distclean &&]
	printf "\n" &&
	printf "${GRE}${bold}Done.\n" &&
	printf "\n" &&
	tput sgr0
}
case $1 in
	--clean) makeClean; exit 0;;
esac

printf "\n" &&
printf "${YEL}Building Geany-ng...\n" &&
printf "${CYA}\n" &&


# Build geany-ng
export CFLAGS="-g0 -s -O3 -mavx -maes -DNDEBUG" &&
export CXXFLAGS="-g0 -s -O3 -mavx -maes -DNDEBUG" &&
export CPPFLAGS="-g0 -s -O3 -mavx -maes -DNDEBUG" &&
export LDFLAGS="-Wl,-O3 -mavx -maes" &&

./autogen.sh &&

./configure --enable-the-force &&

make VERBOSE=1 V=1 &&

printf "\n" &&
printf "${GRE}${bold}Build Completed. ${YEL}${bold}You can now run \`sudo make install\` or \`make install\` to install it.\n" &&
printf "\n" &&
tput sgr0 &&

exit 0
