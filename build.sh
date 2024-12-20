#!/bin/bash

# Copyright (c) 2024 Alex313031.

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
	printf "${bold}${YEL}Use the --deps flag to install build dependencies.${c0}\n" &&
	printf "${bold}${YEL}Use the --debug flag to make a debug build.${c0}\n" &&
	printf "${bold}${YEL}Use the --sse3 flag to make an SSE3 build.${c0}\n" &&
	printf "${bold}${YEL}Use the --sse4 flag to make an SSE4.1 build.${c0}\n" &&
	printf "${bold}${YEL}Use the --help flag to show this help.${c0}\n" &&
	printf "\n"
}
case $1 in
	--help) displayHelp; exit 0;;
esac

installDeps () {
	printf "\n" &&
	printf "${bold}${GRE}Installing build dependencies...${c0}" &&
	printf "\n" &&
	sudo apt install 
}
case $1 in
	--deps) installDeps; exit 0;;
esac

# Clean artifacts
makeClean () {
	printf "\n" &&
	printf "${YEL}Running \`make clean\` and \`make distclean\`..." &&
	printf "${CYA}\n" &&
	make clean && make distclean &&
	printf "\n" &&
	printf "${GRE}${bold}Done." &&
	printf "\n" &&
	tput sgr0
}
case $1 in
	--clean) makeClean; exit 0;;
esac

buildSSE3 () {
printf "\n" &&
printf "${YEL}Building Geany-ng (SSE3 Version)..." &&
printf "${CYA}\n" &&

# Build geany-ng for SSE3
export CFLAGS="-g0 -s -O3 -msse3 -flto=auto -Wno-deprecated-declarations -DNDEBUG" &&
export CXXFLAGS="-g0 -s -O3 -msse3 -flto=auto -DNDEBUG" &&
export CPPFLAGS="-g0 -s -O3 -msse3 -flto=auto -DNDEBUG" &&
export LFLAGS="-Wl,-O3 -msse3 -s -flto=auto" &&
export LDLIBS="-Wl,-O3 -msse3 -s -flto=auto" &&
export LDFLAGS="-Wl,-O3 -msse3 -msse4.1 -s -flto=auto" &&
export OPT_LEVEL="3" &&
export RUSTFLAGS="-C opt-level=3 -C target-feature=+sse4.1" &&

./autogen.sh &&

./configure --enable-the-force &&

make VERBOSE=1 V=1 -j4 &&

printf "\n" &&
printf "${GRE}${bold}Build Completed. ${YEL}${bold}You can now run \`sudo make install\` or \`make install\` to install it." &&
printf "\n" &&
tput sgr0
}
case $1 in
	--sse3) buildSSE3; exit 0;;
esac

buildSSE41 () {
printf "\n" &&
printf "${YEL}Building Geany-ng (SSE4.1 Version)..." &&
printf "${CYA}\n" &&

# Build geany-ng for SSE4.1
export CFLAGS="-g0 -s -O3 -msse4.1 -flto=auto -Wno-deprecated-declarations -DNDEBUG" &&
export CXXFLAGS="-g0 -s -O3 -msse4.1 -flto=auto -DNDEBUG" &&
export CPPFLAGS="-g0 -s -O3 -msse4.1 -flto=auto -DNDEBUG" &&
export LFLAGS="-Wl,-O3 -msse4.1 -s -flto=auto" &&
export LDLIBS="-Wl,-O3 -msse4.1 -s -flto=auto" &&
export LDFLAGS="-Wl,-O3 -msse4.1 -s -flto=auto" &&
export OPT_LEVEL="3" &&
export RUSTFLAGS="-C opt-level=3 -C target-feature=+sse4.1" &&

./autogen.sh &&

./configure --enable-the-force &&

make VERBOSE=1 V=1 -j4 &&

printf "\n" &&
printf "${GRE}${bold}Build Completed. ${YEL}${bold}You can now run \`sudo make install\` or \`make install\` to install it." &&
printf "\n" &&
tput sgr0
}
case $1 in
	--sse4) buildSSE41; exit 0;;
esac

printf "\n" &&
printf "${YEL}Building Geany-ng..." &&
printf "${CYA}\n" &&

# Build geany-ng for AVX
export CFLAGS="-g0 -s -O3 -mavx -maes -flto=auto -Wno-deprecated-declarations -DNDEBUG" &&
export CXXFLAGS="-g0 -s -O3 -mavx -maes -flto=auto -DNDEBUG" &&
export CPPFLAGS="-g0 -s -O3 -mavx -maes -flto=auto -DNDEBUG" &&
export LFLAGS="-Wl,-O3 -mavx -maes -s -flto=auto" &&
export LDLIBS="-Wl,-O3 -mavx -maes -s -flto=auto" &&
export LDFLAGS="-Wl,-O3 -mavx -maes -s -flto=auto" &&
export OPT_LEVEL="3" &&
export RUSTFLAGS="-C opt-level=3 -C target-feature=+avx,+aes" &&

./autogen.sh &&

./configure --enable-the-force &&

make VERBOSE=1 V=1 -j4 &&

printf "\n" &&
printf "${GRE}${bold}Build Completed. ${YEL}${bold}You can now run \`sudo make install\` or \`make install\` to install it." &&
printf "\n" &&
tput sgr0 &&

exit 0
