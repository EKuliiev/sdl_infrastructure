#!/bin/bash

source $( dirname $( realpath -s $0 ) )/helpers.sh

set -e

trap 'on_abort "Preparation SDL_ATF FAILED"' ERR SIGQUIT SIGTERM SIGINT
trap 'on_success "Preparation SDL_ATF successfully finished"' EXIT

on_startup "Preparation SDL_ATF .."

echo "Checking submodules for $build_utils_source_dir.."
git -C $build_utils_source_dir submodule update --init

echo "Checking submodules for $sdl_atf_source_dir.."
git -C $sdl_atf_source_dir submodule update --init

cp -f $sdl_core_source_dir/src/components/interfaces/HMI_API.xml $sdl_atf_source_dir/data
cp -f $sdl_core_source_dir/src/components/interfaces/MOBILE_API.xml $sdl_atf_source_dir/data

$build_utils_source_dir/build_atf.sh

ln -sf $sdl_atf_test_scripts_source_dir/files $sdl_atf_source_dir
ln -sf $sdl_atf_test_scripts_source_dir/test_scripts $sdl_atf_source_dir
ln -sf $sdl_atf_test_scripts_source_dir/user_modules $sdl_atf_source_dir
ln -sf $sdl_atf_test_scripts_source_dir/test_sets $sdl_atf_source_dir

cp -f $build_utils_source_dir/atf/start_test.sh $sdl_atf_source_dir
cp -f $build_utils_source_dir/atf/scripts/run.sh $sdl_atf_source_dir
