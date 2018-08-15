#!/bin/bash

source $( dirname $( realpath -s $0 ) )/helpers.sh

trap 'on_abort Building SDL_ATF failed' ERR SIGQUIT SIGTERM SIGINT
trap 'on_success Build SDL_ATF done' EXIT
on_startup "Building SDL_ATF.."

set -e

qmake --version > /dev/null 2>&1 || { echo " ---> qmake NOT found. Install qmake."; exit 1; }

export QMAKE=$( which qmake )

cd $project_source_dir/sdl_atf
make -j`nproc`
cd -
