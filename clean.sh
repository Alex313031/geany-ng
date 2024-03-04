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
	printf "${bold}${GRE}Script to clean Geany-ng build artifacts.${c0}\n" &&
	printf "${bold}${YEL}Use the --help flag to show this help.${c0}\n" &&
	printf "\n"
}
case $1 in
	--help) displayHelp; exit 0;;
esac

# Clean artifacts
printf "\n" &&
printf "${YEL}Running \`make clean\` and \`make distclean\`..." &&
printf "${CYA}\n" &&
make clean
make distclean
rm -rfv ./dist/* &&
rm -rfv ./geany_build/* &&
rm -fv ./clean &&
printf "\n" &&
printf "${GRE}${bold}Done." &&
printf "\n" &&
tput sgr0

