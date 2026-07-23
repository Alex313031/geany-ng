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
  $SCRIPTNAME [options] - Builds Geany-ng for Linux.

Options:
  -h, --help                  Show this help.
  --version                   Show script version.
  --deps                      Install prerequisites for using this script (Ubuntu/Debian only).
  -j <count>, --jobs <count>  Override make job count. (default: $JOBS)
  -d, --debug                 Create a debug build (default is release mode).
  -v, --verbose               Show verbose build output.
  --sse3                      Compiles targeting SSE3.
  --sse41                     Compiles targeting SSE4.1.
  --sse42                     Compiles targeting SSE4.2.
  --avx                       Compiles targeting AVX.
  --avx2                      Compiles targeting AVX2.
  --x86                       Compiles for x86.
  --x64                       Compiles for x86_64.
  --arm64                     Compiles for arm64.
  -c, --clean                 Runs "make clean" and "make distclean".
  --distclean                 Runs "make distclean".
EOF
}

show_version() {
  printf "\n ${BOLD} %s Version: ${ULINE}%s${C0}\n\n" "$SCRIPTNAME" "$SCRIPTVER"
  exit 0
}

install_deps() {
  if ! command -v apt-get >/dev/null; then
    error_exit "--deps only supports apt-based systems (Ubuntu/Debian); install the prerequisites manually"
  fi
  # use sudo only when not already root (e.g. plain CI containers lack sudo)
  local sudo=""
  [ "$(id -u)" -ne 0 ] && sudo="sudo"

  printf "${GRE}Installing dependencies for $SCRIPTNAME...${C0}\n"
  $sudo apt-get update || error_exit "apt-get update failed"
  # For a 32 bit build, also install gcc-multilib and libgtk-3-dev:i386
  $sudo apt-get install -y \
        build-essential gcc g++ zip unzip tar git \
        autoconf autopoint automake pkg-config m4 \
        libgtk-3-dev intltool gettext libtool python3-docutils \
      || error_exit "Failed to install dependencies"
  printf "${GRE}Done installing dependencies!${C0}\n"
}

clean () {
  cd "$HERE" || error_exit "Could not cd into $HERE"
  [ -f Makefile ] || error_exit "Nothing to clean (no Makefile in $HERE)"
  printf "\n${YEL}Running \`make clean\`..."
  printf "${CYA}\n"
  make clean || error_exit "make clean failed"
  printf "\n${GRE}${BOLD}Done. ${C0}\n"
}

dist_clean () {
  cd "$HERE" || error_exit "Could not cd into $HERE"
  [ -f Makefile ] || error_exit "Nothing to clean (no Makefile in $HERE)"
  printf "\n${YEL}Running \`make distclean\`..."
  printf "${CYA}\n"
  make distclean || error_exit "make distclean failed"
  printf "\n${GRE}${BOLD}Done. ${C0}\n"
}

build () {
  if [ "$IS_ARM" == "1" ] && [ -n "$USE_SSE3$USE_SSE41$USE_SSE42$USE_AVX$USE_AVX2" ]; then
    error_exit "SSE/AVX flags cannot be combined with an arm64 target"
  fi
  if [ "$IS_X86" == "1" ] && [ -n "$USE_AVX$USE_AVX2" ]; then
    error_exit "AVX flags require an x64 target"
  fi

  local _startmsg="Building Geany-ng"
  local MFLAG=""
  if [ "$IS_ARM" == "1" ]; then
    _startmsg+=" (arm64)"
    local SIMD_FLAGS="-march=armv8-a+simd"
  elif [ "$IS_X86" == "1" ] || [ "$IS_X64" == "1" ]; then
    local SIMD_FLAGS="-mfpmath=sse"
    if [ "$IS_X86" == "1" ]; then
      _startmsg+=" x86"
      MFLAG+="-m32"
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
      MFLAG+="-m64"
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

  export CFLAGS="${OPT_FLAGS} ${LTO_FLAGS} ${MFLAG} -static-libgcc -Wno-deprecated-declarations"
  export CXXFLAGS="${OPT_FLAGS} ${LTO_FLAGS} ${MFLAG} -static-libstdc++"
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

  cd "$HERE" || error_exit "Could not cd into $HERE"

  # automake won't rebuild objects when only CFLAGS change, so
  # clear out any previous variant's objects first
  [ -f Makefile ] && make distclean > /dev/null

  try env NOCONFIGURE=1 ./autogen.sh

  try ./configure --enable-the-force $QUIETFLAG

  try make $VFLAG -j $JOBS

  printf "${GRE}\nBuild Completed. ${BOLD}You can now run \`sudo make install\` or \`make install\` to install it.${C0}\n"
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
    -v|--verbose)
        VERBOSE=1
        ;;
    -d|--debug)
        IS_DEBUG=1
        ;;
    --distclean)
        dist_clean
        exit 0
        ;;
    -c|--clean)
        clean
        dist_clean
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
        IS_ARM=0
        ;;
    --x64|-64|--amd64|--x86_64)
        IS_X86=0
        IS_X64=1
        IS_ARM=0
        ;;
    --arm|-arm|--arm64|-arm64)
        IS_X86=0
        IS_X64=0
        IS_ARM=1
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

# default to the host arch when none was given
if [ -z "$IS_X86$IS_X64$IS_ARM" ]; then
  case "$(uname -m)" in
    x86_64)        IS_X64=1 ;;
    aarch64|arm64) IS_ARM=1 ;;
    i?86)          IS_X86=1 ;;
    *) error_exit "Unknown host arch '$(uname -m)'; pass --x86, --x64, or --arm64" ;;
  esac
fi

build
