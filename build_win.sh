#!/bin/bash

# Copyright (c) 2026 Alex313031.

SCRIPTNAME=$(basename "$0")
SCRIPTVER="2.1.0"

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
  --refresh-gtk               Re-download the GTK bundle even if the one on disk is usable.
  --allow-ucrt                Permit building in a UCRT shell (the result will not run on Windows 7).
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

# MSYS2 environments linking against the UCRT instead of msvcrt. ucrtbase.dll is
# only in-box from Windows 10 1507 onward and needs KB2999226 on Windows 7 SP1,
# so these cannot produce the out-of-the-box Windows 7 support geany-ng targets.
is_ucrt_shell() {
  case "$MSYSTEM" in
    UCRT64|CLANG64|CLANGARM64) return 0 ;;
    *) return 1 ;;
  esac
}

# The ABI name scripts/gtk-bundle-from-msys2.sh accepts; it only knows the two
# x86_64 ABIs, so this fails for 32bit and clang shells.
bundle_arch_for_shell() {
  case "$MSYSTEM" in
    MINGW64) echo "mingw64" ;;
    UCRT64)  echo "ucrt64" ;;
    *) return 1 ;;
  esac
}

# The GTK bundle is only read by the NSIS installer (see geany.nsi.in), so it is
# fetched for release builds only, and only when the copy on disk is missing,
# incomplete, or built for a different ABI. ReadMe.Dependencies.Geany.txt is
# written second-to-last by the bundle script under "set -e", which makes it a
# reliable marker that the bundle finished; the installer needs it anyway. The
# stamp file records the ABI, since an msvcrt bundle is not interchangeable
# with a UCRT one.
ensure_bundle() {
  local BUNDLE_DIR="${HERE}/geany_build/bundle/geany-gtk"
  local SENTINEL="${BUNDLE_DIR}/ReadMe.Dependencies.Geany.txt"
  local STAMP="${BUNDLE_DIR}/.bundle-abi"

  local BUNDLE_ARCH
  BUNDLE_ARCH=$(bundle_arch_for_shell) || error_exit \
    "The installer needs a GTK bundle, which requires a MINGW64 or UCRT64 shell (current: ${MSYSTEM:-none})"

  if [ "$REFRESH_GTK" != "1" ] && [ -f "$SENTINEL" ] && [ -f "$STAMP" ] &&
     [ "$(cat "$STAMP")" = "$BUNDLE_ARCH" ]; then
    printf "\n${CYA}Reusing the existing ${BUNDLE_ARCH} GTK bundle (pass --refresh-gtk to re-download).${C0}\n"
    return 0
  fi

  if [ -d "$BUNDLE_DIR" ]; then
    # the bundle script extracts over whatever is already there, so a partial or
    # wrong-ABI bundle would get mixed into the new one; start clean instead
    if [ "$REFRESH_GTK" = "1" ]; then
      printf "\n${YEL}Removing the existing GTK bundle to re-download it...${C0}\n"
    else
      printf "\n${YEL}Discarding the unusable GTK bundle in ${BUNDLE_DIR}...${C0}\n"
    fi
    rm -rf "$BUNDLE_DIR" || error_exit "Could not remove ${BUNDLE_DIR}"
  fi

  printf "\n${YEL}Downloading the GTK bundle (${BUNDLE_ARCH}) for making the installer..."
  printf "${CYA}\n"
  mkdir -p "$BUNDLE_DIR" || error_exit "Could not create the bundle directory"
  # in a subshell so the build's working directory is left alone
  ( cd "$BUNDLE_DIR" &&
      try bash "${HERE}/scripts/gtk-bundle-from-msys2.sh" "--${BUNDLE_ARCH}" -c -3 ) ||
    error_exit "Failed to create the GTK bundle"
  [ -f "$SENTINEL" ] ||
    error_exit "The GTK bundle looks incomplete: ${SENTINEL} was never created"
  echo "$BUNDLE_ARCH" > "$STAMP" || error_exit "Could not write ${STAMP}"
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
  # a UCRT build looks completely normal and installs fine, it just refuses to
  # start on Windows 7, so refuse here rather than let it ship unnoticed
  if is_ucrt_shell; then
    if [ "$ALLOW_UCRT" != "1" ]; then
      error_exit "$MSYSTEM links against the UCRT, which Windows 7 does not ship out of the box.
Geany-ng targets Windows 7, so builds are expected to come from a MINGW64 shell.
Re-run this from a MINGW64 shell, or pass --allow-ucrt to build anyway."
    fi
    printf "\n${RED}${BOLD}Warning:${C0}${RED} building against the UCRT (${MSYSTEM}).${C0}\n"
    printf "${RED}This build will not start on Windows 7 without KB2999226 installed.${C0}\n"
  fi

  local _startmsg="Building Geany-ng"
  local SIMD_FLAGS="-mfpmath=sse"
  local SIMD_TAG=""
  if [ "$IS_X86" == "1" ]; then
    _startmsg+=" x86"
    # SSE2 baseline
    if [ -z "$USE_SSE3$USE_SSE41$USE_SSE42" ]; then
      _startmsg+=" (SSE2 Version)"
      SIMD_FLAGS+=" -mfxsr -msse2"
      SIMD_TAG="sse2"
    fi
    if [ "$USE_SSE3" == "1" ]; then
      _startmsg+=" (SSE3 Version)"
      SIMD_FLAGS+=" -msse3"
      SIMD_TAG="sse3"
    fi
    if [ "$USE_SSE41" == "1" ]; then
      _startmsg+=" (SSE4.1 Version)"
      SIMD_FLAGS+=" -mssse3 -msse4.1"
      SIMD_TAG="sse41"
    fi
    if [ "$USE_SSE42" == "1" ]; then
      _startmsg+=" (SSE4.2 Version)"
      SIMD_FLAGS+=" -msse4.2"
      SIMD_TAG="sse42"
    fi
  elif [ "$IS_X64" == "1" ]; then
    _startmsg+=" x64"
    if [ -z "$USE_SSE3$USE_SSE41$USE_SSE42$USE_AVX$USE_AVX2" ]; then
      _startmsg+=" (SSE2 Version)"
      SIMD_FLAGS+=" -msse2 -march=x86-64"
      SIMD_TAG="sse2"
    fi
    if [ "$USE_SSE3" == "1" ]; then
      _startmsg+=" (SSE3 Version)"
      SIMD_FLAGS+=" -msse3"
      SIMD_TAG="sse3"
    fi
    if [ "$USE_SSE41" == "1" ]; then
      _startmsg+=" (SSE4.1 Version)"
      SIMD_FLAGS+=" -mssse3 -msse4.1"
      SIMD_TAG="sse41"
    fi
    if [ "$USE_SSE42" == "1" ]; then
      _startmsg+=" (SSE4.2 Version)"
      SIMD_FLAGS+=" -msse4.2 -march=x86-64-v2"
      SIMD_TAG="sse42"
    fi
    if [ "$USE_AVX" == "1" ]; then
      _startmsg+=" (AVX Version)"
      SIMD_FLAGS+=" -mavx -maes"
      SIMD_TAG="avx"
    fi
    if [ "$USE_AVX2" == "1" ]; then
      _startmsg+=" (AVX2 Version)"
      SIMD_FLAGS+=" -mavx2 -mfma -march=x86-64-v3"
      SIMD_TAG="avx2"
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

  export CFLAGS="${OPT_FLAGS} ${LTO_FLAGS} -Wno-deprecated-declarations"
  export CXXFLAGS="${OPT_FLAGS} ${LTO_FLAGS}"
  export CPPFLAGS="${CXXFLAGS}"
  export LDFLAGS="${LTO_FLAGS} ${STRIP_FLAG} -static-libgcc -static-libstdc++"

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

  # likewise the GTK bundle, fetched before the compile so a bundle problem
  # surfaces immediately instead of after a full build
  if [ "$IS_DEBUG" != "1" ]; then
    ensure_bundle
  elif [ "$REFRESH_GTK" = "1" ]; then
    printf "\n${YEL}Ignoring --refresh-gtk: debug builds make no installer.${C0}\n"
  fi

  # Remove _build entirely: automake does not rebuild objects when only CFLAGS
  # change, so stale objects from a previous SIMD variant would end up in this
  # one. The install prefix is wiped too so each install is hermetic.
  rm -rf _build "${DESTINATION}/build"

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
    try python3 "${HERE}/geany-release.py" "$VERSION" "$SIMD_TAG"
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
        error_exit "'--gtk' was removed: the GTK bundle is now created automatically for release builds.
Use --refresh-gtk to force a re-download of it."
        ;;
    --refresh-gtk)
        REFRESH_GTK=1
        ;;
    --allow-ucrt)
        ALLOW_UCRT=1
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
