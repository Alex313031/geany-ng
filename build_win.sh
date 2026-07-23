#!/bin/bash

# Copyright (c) 2026 Alex313031.

SCRIPTNAME=$(basename "$0")
SCRIPTVER="2.0.1"

# Colors
YEL='\033[1;33m'  # Yellow
CYA='\033[1;96m'  # Cyan
RED='\033[1;31m'  # Red
GRE='\033[1;32m'  # Green
C0='\033[0;00m'   # Reset Text
BOLD='\033[1;37m' # Bold Text
ULINE='\033[4m'   # Underline Text

# Error handling
yell() { printf "%b\n" "$0: $*${C0}" >&2; }
die() { yell "$*"; exit 111; }
try() { "$@" || die "${RED}Failed $*"; }

export HERE=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Used by geany.nsi.in and geany-release.py when building the installer
export GEANY_SOURCE_DIR="${HERE}"

JOBS=$(getconf _NPROCESSORS_ONLN) # Default to num processors

error_exit() {
  local error_msg="$1"
  shift 1

  if [ "$error_msg" ]; then
    printf "${RED}%s${C0}\n" "$error_msg" >&2
  else
    printf "${RED}An error occurred.${C0}\n" >&2
  fi
  exit 1
}

arg_error() {
  local error_msg="$1"
  shift 1

  error_exit "$error_msg, see --help for options"
}

show_help() {
  cat <<EOF
Usage:
  $SCRIPTNAME [options] - Builds a Geany-ng installer for Windows (MSYS2).

Options:
  -h, --help                  Show this help.
  --version                   Show script version.
  --deps                      Install MSYS2 prerequisites for using this script.
  --gtk                       Download the GTK bundle used to make the installer (arch follows the MSYS2 shell).
  -j <count>, --jobs <count>  Override make job count. (default: $JOBS)
  -d, --debug                 Create a debug build (default is release mode; debug builds make no installer).
  -v, --verbose               Show verbose build output.
  --sse3                      Compiles targeting SSE3.
  --sse41                     Compiles targeting SSE4.1.
  --sse42                     Compiles targeting SSE4.2.
  --avx                       Compiles targeting AVX.
  --avx2                      Compiles targeting AVX2.
  --x86                       Compiles for x86 (requires a MINGW32 shell).
  --x64                       Compiles for x86_64.
  -c, --clean                 Removes previous build artifacts (keeps the GTK bundle).
EOF
}

show_version() {
  printf "\n ${BOLD} %s Version: ${ULINE}%s${C0}\n\n" "$SCRIPTNAME" "$SCRIPTVER"
  exit 0
}

install_deps() {
  if ! command -v pacman >/dev/null; then
    error_exit "--deps requires an MSYS2 shell with pacman; install the prerequisites manually"
  fi

  printf "${GRE}Installing MSYS2 dependencies for $SCRIPTNAME...${C0}\n"
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
            ${MINGW_PACKAGE_PREFIX}-zstd \
    || error_exit "Failed to install dependencies"
  printf "${GRE}Done installing dependencies!${C0}\n"
}

download_bundle() {
  # scripts/gtk-bundle-from-msys2.sh only knows the MINGW64 and UCRT64 ABIs
  local BUNDLE_ARCH
  case "$MSYSTEM" in
    MINGW64) BUNDLE_ARCH="--mingw64" ;;
    UCRT64)  BUNDLE_ARCH="--ucrt64" ;;
    *) error_exit "--gtk requires a MINGW64 or UCRT64 shell (current: ${MSYSTEM:-none})" ;;
  esac

  printf "\n${YEL}Downloading the GTK bundle (${BUNDLE_ARCH#--}) for making the installer..."
  printf "${CYA}\n"
  mkdir -p "${HERE}/geany_build/bundle/geany-gtk" || error_exit "Could not create the bundle directory"
  cd "${HERE}/geany_build/bundle/geany-gtk" || error_exit "Could not cd into the bundle directory"
  try bash "${HERE}/scripts/gtk-bundle-from-msys2.sh" "$BUNDLE_ARCH" -c -3
  printf "\n${GRE}${BOLD}Done. ${C0}\n"
}

# Clean artifacts (keeps geany_build/bundle so the GTK bundle isn't redownloaded)
clean () {
  cd "$HERE" || error_exit "Could not cd into $HERE"
  printf "\n${YEL}Removing previous build artifacts..."
  printf "${CYA}\n"
  rm -rf "${HERE}/_build" "${HERE}/geany_build/build" "${HERE}/geany_build/release" \
    || error_exit "Failed to remove build artifacts"
  printf "\n${GRE}${BOLD}Done. ${C0}\n"
}

build () {
  if [ "$IS_X86" == "1" ] && [ -n "$USE_AVX$USE_AVX2" ]; then
    error_exit "AVX flags require an x64 target"
  fi
  # MSYS2 toolchains target one arch per shell, so the requested arch
  # has to match the shell we are running in
  if [ "$IS_X86" == "1" ] && [ "$MSYSTEM" != "MINGW32" ] && [ "$MSYSTEM" != "CLANG32" ]; then
    error_exit "x86 builds require a MINGW32 shell (current: ${MSYSTEM:-none})"
  fi
  if [ "$IS_X64" == "1" ] && { [ "$MSYSTEM" == "MINGW32" ] || [ "$MSYSTEM" == "CLANG32" ]; }; then
    error_exit "x64 builds require a MINGW64/UCRT64 shell (current: $MSYSTEM)"
  fi

  local _startmsg="Building Geany-ng"
  local SIMD_FLAGS="-mfpmath=sse"
  if [ "$IS_X86" == "1" ]; then
    _startmsg+=" x86"
    # SSE2 baseline
    SIMD_FLAGS+=" -msse -mfxsr -msse2"
    if [ "$USE_SSE3" == "1" ]; then
      _startmsg+=" (SSE3 Version)"
      SIMD_FLAGS+=" -msse3"
    fi
    if [ "$USE_SSE41" == "1" ]; then
      _startmsg+=" (SSE4.1 Version)"
      SIMD_FLAGS+=" -mssse3 -msse4.1"
    fi
    if [ "$USE_SSE42" == "1" ]; then
      _startmsg+=" (SSE4.2 Version)"
      SIMD_FLAGS+=" -msse4.2"
    fi
  elif [ "$IS_X64" == "1" ]; then
    _startmsg+=" x64"
    if [ "$USE_SSE3" == "1" ]; then
      _startmsg+=" (SSE3 Version)"
      SIMD_FLAGS+=" -msse3"
    fi
    if [ "$USE_SSE41" == "1" ]; then
      _startmsg+=" (SSE4.1 Version)"
      SIMD_FLAGS+=" -mssse3 -msse4.1"
    fi
    if [ "$USE_SSE42" == "1" ]; then
      _startmsg+=" (SSE4.2 Version)"
      SIMD_FLAGS+=" -msse4.2 -march=x86-64-v2"
    fi
    if [ "$USE_AVX" == "1" ]; then
      _startmsg+=" (AVX Version)"
      SIMD_FLAGS+=" -mavx -maes"
    fi
    if [ "$USE_AVX2" == "1" ]; then
      _startmsg+=" (AVX2 Version)"
      SIMD_FLAGS+=" -mavx2 -mfma -march=x86-64-v3"
    fi
  else
    error_exit "Unsupported arch"
  fi

  printf "\n${YEL}${_startmsg} using ${JOBS} jobs...${C0}\n"

  local OPT_FLAGS="${SIMD_FLAGS}"
  if [ "$IS_DEBUG" = "1" ]; then
    OPT_FLAGS+=" -Og -g2 -DDEBUG -D_DEBUG -DGEANY_DEBUG"
    local LTO_FLAGS="-Wl,-O0"
    local STRIP_FLAG=""
  else
    OPT_FLAGS+=" -O3 -g0 -DNDEBUG -D_NDEBUG"
    local LTO_FLAGS="-Wl,-O3 -flto=auto"
    local STRIP_FLAG="-s"
  fi

  export CFLAGS="${OPT_FLAGS} ${LTO_FLAGS} -static-libgcc -Wno-deprecated-declarations"
  export CXXFLAGS="${OPT_FLAGS} ${LTO_FLAGS} -static-libstdc++"
  export CPPFLAGS="${CXXFLAGS}"
  export LDFLAGS="${LTO_FLAGS} ${STRIP_FLAG}"

  if [ "$VERBOSE" = "1" ]; then
    local VFLAG="VERBOSE=1 V=1"
    local QUIETFLAG="--disable-silent-rules"
    printf "${CYA}CFLAGS   ${C0}= ${BOLD}${CFLAGS} ${C0}\n"
    printf "${CYA}CXXFLAGS ${C0}= ${BOLD}${CXXFLAGS} ${C0}\n"
    printf "${CYA}CPPFLAGS ${C0}= ${BOLD}${CPPFLAGS} ${C0}\n"
    printf "${CYA}LDFLAGS  ${C0}= ${BOLD}${LDFLAGS} ${C0}\n"
  else
    local VFLAG=""
    local QUIETFLAG="--quiet"
    printf "${CYA}SIMD_FLAGS ${C0}= ${BOLD}${SIMD_FLAGS} ${C0}\n"
  fi

  printf "${CYA}\n"

  local DESTINATION="${HERE}/geany_build"

  cd "$HERE" || error_exit "Could not cd into $HERE"

  # the installer bundles colorschemes from the geany-themes submodule, so
  # populate it up front if this clone hasn't yet; an already-populated
  # submodule is left alone so local changes get packaged as-is
  if [ "$IS_DEBUG" != "1" ] && [ ! -d "${HERE}/geany-themes/colorschemes" ]; then
    try git -C "${HERE}" submodule update --init geany-themes
  fi

  # Remove _build entirely: automake does not rebuild objects when only CFLAGS
  # change, so stale objects from a previous SIMD variant would end up in this one
  rm -rf _build

  local VERSION
  VERSION=$(autom4te --no-cache --language=Autoconf-without-aclocal-m4 --trace AC_INIT:\$2 configure.ac) \
    || error_exit "Failed to read the version from configure.ac"

  try env NOCONFIGURE=1 ./autogen.sh

  export lt_cv_deplibs_check_method="${lt_cv_deplibs_check_method:-pass_all}"

  mkdir -p _build
  cd _build || error_exit "Could not cd into _build"

  try ../configure --disable-rpath --enable-the-force --prefix="${DESTINATION}/build" $QUIETFLAG

  # the parallel make's result is deliberately ignored: parallel builds can
  # fail spuriously under MSYS2, so the serial make afterwards either finishes
  # the job or surfaces the real error
  make $VFLAG -j $JOBS
  try make $VFLAG

  # src/geany.exe is only libtool's wrapper stub (used to locate the uninstalled
  # libgeany DLL when running from the build tree) and never gets the .res/icon;
  # the real resource-linked binary lives in src/.libs/, so force it through
  try cp -f -v src/.libs/geany.exe src/geany.exe

  if [ "$IS_DEBUG" = "1" ]; then
    try make install
  else
    try make install-strip
  fi

  if [ "$IS_DEBUG" = "1" ]; then
    printf "${GRE}\nBuild Completed. ${BOLD}You can find it in ${DESTINATION}/build/${C0}\n"
  else
    printf "\n${YEL}Building .exe Installer...${C0}\n\n"
    try python3 "${HERE}/geany-release.py" "$VERSION"
    printf "${GRE}\nBuild Completed. ${BOLD}You can find it in ${DESTINATION}/${C0}\n"
  fi
}

# Cmdline handling
while :; do
  case $1 in
    -h|--help)
        show_help
        exit 0
        ;;
    --version)
        show_version
        ;;
    --deps)
        install_deps
        exit 0
        ;;
    --gtk)
        download_bundle
        exit 0
        ;;
    -v|--verbose)
        VERBOSE=1
        ;;
    -d|--debug)
        IS_DEBUG=1
        ;;
    -c|--clean)
        clean
        exit 0
        ;;
    -j|--jobs)
        if [[ "$2" =~ ^[1-9][0-9]*$ ]]; then
          JOBS=$2
          shift
        else
          arg_error "'--jobs' requires a numeric argument"
        fi
        ;;
    --sse3)
        USE_SSE3=1
        ;;
    --sse41)
        USE_SSE41=1
        ;;
    --sse42)
        USE_SSE42=1
        ;;
    --avx)
        IS_X64=1
        USE_AVX=1
        ;;
    --avx2)
        IS_X64=1
        USE_AVX2=1
        ;;
    --x86|-32|--i686|--x32)
        IS_X86=1
        IS_X64=0
        ;;
    --x64|-64|--amd64|--x86_64)
        IS_X86=0
        IS_X64=1
        ;;
    --)
        shift
        break
        ;;
    -?*)
        arg_error "Unknown option '$1'"
        ;;
    *)
        break
  esac

  shift
done

# default to the MSYS2 shell's target arch when none was given
if [ -z "$IS_X86$IS_X64" ]; then
  case "$MSYSTEM" in
    MINGW32|CLANG32)        IS_X86=1 ;;
    MINGW64|UCRT64|CLANG64) IS_X64=1 ;;
    *) error_exit "Unrecognized MSYS2 shell '${MSYSTEM:-none}'; run from a MinGW shell or pass --x86 or --x64" ;;
  esac
fi

build
