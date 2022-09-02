#!/bin/bash

export CFLAGS="-g0 -s -O3 -mavx -maes -DNDEBUG" &&
export CXXFLAGS="-g0 -s -O3 -mavx -maes -DNDEBUG" &&
export CPPFLAGS="-g0 -s -O3 -mavx -maes -DNDEBUG" &&
export LDFLAGS="-Wl,-O3 -mavx -maes" &&

./autogen.sh &&

make clean &&

./configure --enable-the-force &&

make VERBOSE=1 V=1 &&

exit 0
