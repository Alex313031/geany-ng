#!/usr/bin/env python3

import glob
import os
import shutil
import subprocess
import sys

if len(sys.argv) != 3:
    print('Usage: update-ctags.py <universal ctags directory> <geany ctags directory>')
    sys.exit(1)

srcdir = os.path.abspath(sys.argv[1])
dstdir = os.path.abspath(sys.argv[2])

os.chdir(dstdir + '/parsers')
parser_dst_files = glob.glob('*.c') + glob.glob('*.h')
parser_dst_files = list(filter(lambda x: not x.startswith('geany_'), parser_dst_files))
cxx_parser_dst_files = glob.glob('cxx/*.c') + glob.glob('cxx/*.h')
for f in cxx_parser_dst_files:
    os.remove(f)

os.chdir(srcdir + '/parsers')
print('Copying parsers... ({} files)'.format(len(parser_dst_files)))
for f in parser_dst_files:
    shutil.copy(f, dstdir + '/parsers')

cxx_parser_src_files_excludes = [
    'cxx/cxx_jni.c',
]
cxx_parser_src_files = [f for f in glob.glob('cxx/*.c') + glob.glob('cxx/*.h')
                        if (f in cxx_parser_dst_files or
                            f not in cxx_parser_src_files_excludes)]
print('Copying cxx parser files... ({} files)'.format(len(cxx_parser_src_files)))
for f in cxx_parser_src_files:
    shutil.copy(f, dstdir + '/parsers/cxx')

os.chdir(dstdir + '/optlib')
optlib_parser_dst_files = glob.glob('*.c')
os.chdir(srcdir + '/optlib')
print('Copying optlib parsers... ({} files)'.format(len(optlib_parser_dst_files)))
for f in optlib_parser_dst_files:
    shutil.copy(f, dstdir + '/optlib')

print('Copying dsl files...')
for f in ['dsl/es.c', 'dsl/es.h', 'dsl/optscript.c', 'dsl/optscript.h']:
    shutil.copy(srcdir + '/' + f, dstdir + '/' + f)

print('Copying libreadtags files...')
for f in ['libreadtags/readtags.c', 'libreadtags/readtags.h']:
    shutil.copy(srcdir + '/' + f, dstdir + '/' + f)

os.chdir(dstdir)
main_dst_files = glob.glob('main/*.c') + glob.glob('main/*.h')
os.chdir(srcdir)
# files that should not be copied over (not used by the parts of CTags we use),
# unless they were already present in the local copy
main_src_files_excludes = [
    'main/fname.c',
    'main/fname.h',
    'main/intern.c',
    'main/intern.h',
]
main_src_files = [f for f in glob.glob('main/*.c') + glob.glob('main/*.h')
                  if f in main_dst_files or f not in main_src_files_excludes]

os.chdir(dstdir)
for f in main_dst_files:
    os.remove(f)
os.chdir(srcdir)
print('Copying main... ({} files)'.format(len(main_src_files)))
for f in main_src_files:
    shutil.copy(f, dstdir + '/main')

os.chdir(dstdir)
patches = glob.glob('patches/*.patch')
if patches:
    print('Applying local patches...')
    for patch in patches:
        subprocess.run(['git', 'apply', '--', patch], check=True,
                       stdout=subprocess.DEVNULL)

main_diff = set(main_dst_files) - set(main_src_files)
if main_diff:
    print('Files removed from main: ' + str(main_diff))
main_diff = set(main_src_files) - set(main_dst_files)
if main_diff:
    print('Files added to main: ' + str(main_diff))
