#!/bin/bash

# Copyright (c) 2025 Alex313031.

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
	printf "${bold}${GRE}Script to build a Geany-ng installer on Windows.${c0}\n" &&
	printf "${bold}${YEL}Use the --clean flag to run \`make clean\` & \`make distclean\`.${c0}\n" &&
	printf "${bold}${YEL}Use the --deps flag to install build dependencies.${c0}\n" &&
	printf "${bold}${YEL}Use the --debug flag to make a debug build (with no installer).${c0}\n" &&
	printf "${bold}${YEL}Use the --gtk flag to download GTK bundle for making installer.${c0}\n" &&
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
	pacman -S base-devel git patch rsync wget curl tar dos2unix zip unzip ed autoconf automake gettext make cmake \
            mingw-w64-i686-toolchain \
            ${MINGW_PACKAGE_PREFIX}-gcc \
            ${MINGW_PACKAGE_PREFIX}-autotools \
            ${MINGW_PACKAGE_PREFIX}-gtk3 \
            ${MINGW_PACKAGE_PREFIX}-pkgconf \
            ${MINGW_PACKAGE_PREFIX}-python3 \
            ${MINGW_PACKAGE_PREFIX}-python-docutils \
            ${MINGW_PACKAGE_PREFIX}-python-lxml \
            ${MINGW_PACKAGE_PREFIX}-binutils \
            ${MINGW_PACKAGE_PREFIX}-check \
            ${MINGW_PACKAGE_PREFIX}-cppcheck \
            ${MINGW_PACKAGE_PREFIX}-ctpl-git \
            ${MINGW_PACKAGE_PREFIX}-enchant \
            ${MINGW_PACKAGE_PREFIX}-gdb \
            ${MINGW_PACKAGE_PREFIX}-gpgme \
            ${MINGW_PACKAGE_PREFIX}-gtkspell3 \
            ${MINGW_PACKAGE_PREFIX}-libgit2 \
            ${MINGW_PACKAGE_PREFIX}-libsoup \
            ${MINGW_PACKAGE_PREFIX}-libsoup3 \
            ${MINGW_PACKAGE_PREFIX}-libtool \
            ${MINGW_PACKAGE_PREFIX}-lua51 \
            ${MINGW_PACKAGE_PREFIX}-nsis \
            ${MINGW_PACKAGE_PREFIX}-osslsigncode &&
  pacman -S \
            ${MINGW_PACKAGE_PREFIX}-adwaita-icon-theme \
            ${MINGW_PACKAGE_PREFIX}-atk \
            ${MINGW_PACKAGE_PREFIX}-brotli \
            ${MINGW_PACKAGE_PREFIX}-bzip2 \
            ${MINGW_PACKAGE_PREFIX}-cairo \
            ${MINGW_PACKAGE_PREFIX}-expat \
            ${MINGW_PACKAGE_PREFIX}-fontconfig \
            ${MINGW_PACKAGE_PREFIX}-freetype \
            ${MINGW_PACKAGE_PREFIX}-fribidi \
            ${MINGW_PACKAGE_PREFIX}-gcc-libs \
            ${MINGW_PACKAGE_PREFIX}-gdk-pixbuf2 \
            ${MINGW_PACKAGE_PREFIX}-gettext-runtime \
            ${MINGW_PACKAGE_PREFIX}-glib2 \
            ${MINGW_PACKAGE_PREFIX}-graphite2 \
            ${MINGW_PACKAGE_PREFIX}-grep \
            ${MINGW_PACKAGE_PREFIX}-gtk3 \
            ${MINGW_PACKAGE_PREFIX}-gtk-update-icon-cache \
            ${MINGW_PACKAGE_PREFIX}-harfbuzz \
            ${MINGW_PACKAGE_PREFIX}-hicolor-icon-theme \
            ${MINGW_PACKAGE_PREFIX}-jbigkit \
            ${MINGW_PACKAGE_PREFIX}-lerc \
            ${MINGW_PACKAGE_PREFIX}-libdatrie \
            ${MINGW_PACKAGE_PREFIX}-libdeflate \
            ${MINGW_PACKAGE_PREFIX}-libepoxy \
            ${MINGW_PACKAGE_PREFIX}-libffi \
            ${MINGW_PACKAGE_PREFIX}-libiconv \
            ${MINGW_PACKAGE_PREFIX}-libjpeg-turbo \
            ${MINGW_PACKAGE_PREFIX}-libpng \
            ${MINGW_PACKAGE_PREFIX}-librsvg \
            ${MINGW_PACKAGE_PREFIX}-libthai \
            ${MINGW_PACKAGE_PREFIX}-libtiff \
            ${MINGW_PACKAGE_PREFIX}-libwebp \
            ${MINGW_PACKAGE_PREFIX}-libwinpthread-git \
            ${MINGW_PACKAGE_PREFIX}-libxml2 \
            ${MINGW_PACKAGE_PREFIX}-pango \
            ${MINGW_PACKAGE_PREFIX}-pcre2 \
            ${MINGW_PACKAGE_PREFIX}-pixman \
            ${MINGW_PACKAGE_PREFIX}-shared-mime-info \
            ${MINGW_PACKAGE_PREFIX}-xz \
            ${MINGW_PACKAGE_PREFIX}-zlib \
            ${MINGW_PACKAGE_PREFIX}-zstd
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

downloadBundle() {
  mkdir -p ~/geany-ng/geany_build/bundle/geany-gtk &&
  cd ~/geany-ng/geany_build/bundle/geany-gtk &&
  bash ~/geany-ng/scripts/gtk-bundle-from-msys2.sh --mingw64 -c -3
}
case $1 in
	--gtk) downloadBundle; exit 0;;
esac

buildSSE41 () {
printf "\n" &&
printf "${YEL}Building Geany-ng (SSE4.1 Version)..." &&
printf "${CYA}\n" &&

# Build geany-ng installer for SSE4.1
export CFLAGS="-g0 -s -O3 -msse4.1 -flto=auto -DNDEBUG" &&
export CXXFLAGS="-g0 -s -O3 -msse4.1 -flto=auto -DNDEBUG" &&
export CPPFLAGS="-g0 -s -O3 -msse4.1 -flto=auto -DNDEBUG" &&
export LFLAGS="-Wl,-O3 -msse4.1 -s -flto=auto" &&
export LDLIBS="-Wl,-O3 -msse4.1 -s -flto=auto" &&
export LDFLAGS="-Wl,-O3 -msse4.1 -s -flto=auto" &&

export DESTINATON=~/geany-ng/geany_build &&

cd ~/geany-ng &&
make distclean
VERSION=$(autom4te --no-cache --language=Autoconf-without-aclocal-m4 --trace AC_INIT:\$2 configure.ac) &&
NOCONFIGURE=1 ./autogen.sh &&
export lt_cv_deplibs_check_method=${lt_cv_deplibs_check_method='pass_all'} &&
mkdir -p _build && cd _build &&
../configure --disable-rpath --enable-the-force --prefix=${DESTINATON}/build --disable-silent-rules &&

cd ~/geany-ng/_build &&
make VERBOSE=1 V=1 -j4
cd ~/geany-ng/_build &&
make &&

# Shouldn't have to do this, IDK why MinGW makes src/geany.exe incorrect one without .res applied
cp -f -v src/.libs/geany.exe src/geany.exe &&

make install &&

printf "\n" &&
printf "${YEL}Building .exe Installer..." &&
printf "${CYA}\n" &&

python3 ~/geany-ng/geany-release.py $VERSION &&

printf "\n" &&
printf "${GRE}${bold}Build Completed. ${YEL}${bold}You can find it in ${DESTINATON}/" &&
printf "\n" &&
tput sgr0
}
case $1 in
	--sse4) buildSSE41; exit 0;;
esac

buildDebug () {
printf "\n" &&
printf "${YEL}Building Geany-ng (Debug SSE2 Version)..." &&
printf "${CYA}\n" &&

# Build geany-ng installer for SSE4.1
export CFLAGS="-g -Og -msse2 -DDEBUG -DGEANY_DEBUG" &&
export CXXFLAGS="-g -Og -msse2 -DDEBUG -DGEANY_DEBUG" &&
export CPPFLAGS="-g -Og -msse2 -DDEBUG -DGEANY_DEBUG" &&
export LFLAGS="-msse2" &&
export LDLIBS="-msse2" &&
export LDFLAGS="-msse2" &&

export DESTINATON=~/geany-ng/geany_build &&

cd ~/geany-ng &&
make distclean
VERSION=$(autom4te --no-cache --language=Autoconf-without-aclocal-m4 --trace AC_INIT:\$2 configure.ac) &&
NOCONFIGURE=1 ./autogen.sh &&
export lt_cv_deplibs_check_method=${lt_cv_deplibs_check_method='pass_all'} &&
mkdir -p _build && cd _build &&
../configure --disable-rpath --enable-the-force --prefix=${DESTINATON}/build --disable-silent-rules &&

cd ~/geany-ng/_build &&
make VERBOSE=1 V=1 -j4
cd ~/geany-ng/_build &&
make &&

# Shouldn't have to do this, IDK why MinGW makes src/geany.exe incorrect one without .res applied
cp -f -v src/.libs/geany.exe src/geany.exe &&

make install &&

printf "\n" &&
printf "${GRE}${bold}Build Completed. ${YEL}${bold}You can find it in ${DESTINATON}/build/geany/" &&
printf "\n" &&
tput sgr0
}
case $1 in
	--debug) buildDebug; exit 0;;
esac

printf "\n" &&
printf "${YEL}Building Geany-ng (AVX)..." &&
printf "${CYA}\n" &&

# Build geany-ng installer for AVX
export CFLAGS="-g0 -s -O3 -mavx -maes -flto=auto -DNDEBUG" &&
export CXXFLAGS="-g0 -s -O3 -mavx -maes -flto=auto -DNDEBUG" &&
export CPPFLAGS="-g0 -s -O3 -mavx -maes -flto=auto -DNDEBUG" &&
export LFLAGS="-Wl,-O3 -mavx -maes -s -flto=auto" &&
export LDLIBS="-Wl,-O3 -mavx -maes -s -flto=auto" &&
export LDFLAGS="-Wl,-O3 -mavx -maes -s -flto=auto" &&

export DESTINATON=~/geany-ng/geany_build &&

cd ~/geany-ng &&
make distclean
VERSION=$(autom4te --no-cache --language=Autoconf-without-aclocal-m4 --trace AC_INIT:\$2 configure.ac) &&
NOCONFIGURE=1 ./autogen.sh &&
export lt_cv_deplibs_check_method=${lt_cv_deplibs_check_method='pass_all'} &&
mkdir -p _build && cd _build &&
../configure --disable-rpath --enable-the-force --prefix=${DESTINATON}/build --disable-silent-rules &&

cd ~/geany-ng/_build &&
make VERBOSE=1 V=1 -j4
cd ~/geany-ng/_build &&
make &&

# Shouldn't have to do this, IDK why MinGW makes src/geany.exe incorrect one without .res applied
cp -f -v src/.libs/geany.exe src/geany.exe &&

make install &&

printf "\n" &&
printf "${YEL}Building .exe Installer..." &&
printf "${CYA}\n" &&

python3 ~/geany-ng/geany-release.py $VERSION &&

printf "\n" &&
printf "${GRE}${bold}Build Completed. ${YEL}${bold}You can find it in ${DESTINATON}/" &&
printf "\n" &&
tput sgr0 &&

exit 0
