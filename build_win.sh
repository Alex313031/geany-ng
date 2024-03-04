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
	printf "${bold}${GRE}Script to build Geany-ng on Windows.${c0}\n" &&
	printf "${bold}${YEL}Use the --clean flag to run \`make clean\` & \`make distclean\`.${c0}\n" &&
	printf "${bold}${YEL}Use the --deps flag to install build dependencies.${c0}\n" &&
	printf "${bold}${YEL}Use the --debug flag to make a debug build.${c0}\n" &&
	printf "${bold}${YEL}Use the --sse4 flag to make an SSE4.1 build.${c0}\n" &&
	printf "${bold}${YEL}Use the --help flag to show this help.${c0}\n" &&
	printf "\n"
}
case $1 in
	--help) displayHelp; exit 0;;
esac

installDeps () {
	printf "\n" &&
	printf "${bold}${GRE}Installing MSYS2 build dependencies...${c0}" &&
	printf "\n" &&
	pacman --needed -Sy bash pacman pacman-mirrors msys2-runtime &&
	pacman -Syuu &&
	pacman -S mingw-w64-x86_64-binutils mingw-w64-x86_64-gcc mingw-w64-x86_64-gdb cmake make mingw-w64-x86_64-libtool mingw-w64-x86_64-pkgconf autoconf automake gettext mingw-w64-x86_64-gtk3 mingw-w64-x86_64-python3 mingw-w64-x86_64-python-lxml git rsync wget curl tar dos2unix zip unzip mingw-w64-x86_64-osslsigncode mingw-w64-x86_64-nsis mingw-w64-x86_64-check mingw-w64-x86_64-enchant mingw-w64-x86_64-lua51 mingw-w64-x86_64-gpgme mingw-w64-x86_64-libsoup mingw-w64-x86_64-libgit2 mingw-w64-x86_64-gtkspell3 mingw-w64-x86_64-ctpl-git mingw-w64-x86_64-python-docutils patch ed
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

buildSSE41 () {
printf "\n" &&
printf "${YEL}Building Geany-ng (SSE4.1 Version)..." &&
printf "${CYA}\n" &&

# Build geany-ng for SSE4.1
export CFLAGS="-g0 -s -O3 -msse4.1 -flto=auto -DNDEBUG" &&
export CXXFLAGS="-g0 -s -O3 -msse4.1 -flto=auto -DNDEBUG" &&
export CPPFLAGS="-g0 -s -O3 -msse4.1 -flto=auto -DNDEBUG" &&
export LFLAGS="-Wl,-O3 -msse4.1 -s -flto=auto" &&
export LDLIBS="-Wl,-O3 -msse4.1 -s -flto=auto" &&
export LDFLAGS="-Wl,-O3 -msse4.1 -s -flto=auto" &&
export OPT_LEVEL="3" &&
export RUSTFLAGS="-C opt-level=3 -C target-feature=+sse4.1" &&

mkdir -p ./dist &&

NOCONFIGURE=1 ./autogen.sh &&

./configure --enable-the-force --prefix=${PWD}/dist &&

make VERBOSE=1 V=1 -j4 &&

make install

printf "\n" &&
printf "${GRE}${bold}Build Completed. ${YEL}${bold}You can find it in \'dist\'." &&
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
export CFLAGS="-g0 -s -O3 -mavx -maes -flto=auto -DNDEBUG" &&
export CXXFLAGS="-g0 -s -O3 -mavx -maes -flto=auto -DNDEBUG" &&
export CPPFLAGS="-g0 -s -O3 -mavx -maes -flto=auto -DNDEBUG" &&
export LFLAGS="-Wl,-O3 -mavx -maes -s -flto=auto" &&
export LDLIBS="-Wl,-O3 -mavx -maes -s -flto=auto" &&
export LDFLAGS="-Wl,-O3 -mavx -maes -s -flto=auto" &&
export OPT_LEVEL="3" &&
export RUSTFLAGS="-C opt-level=3 -C target-feature=+avx,+aes" &&

mkdir -p ./dist &&

NOCONFIGURE=1 ./autogen.sh &&

./configure --enable-the-force --prefix=${PWD}/dist &&

make VERBOSE=1 V=1 -j4 &&

make install

printf "\n" &&
printf "${GRE}${bold}Build Completed. ${YEL}${bold}You can find it in \'dist\'." &&
printf "\n" &&
tput sgr0 &&

exit 0
