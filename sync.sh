#!/bin/bash

source $( dirname $( realpath -s $0 ) )/helpers.sh

trap 'on_abort "Loading SDL components FAILED"' ERR SIGQUIT SIGTERM SIGINT
trap 'on_success "Loading SDL components successfully finished"' EXIT

on_startup "Loading SDL components .."

set -e

echo "Project root source dir: $project_source_dir"

sync_repo "$project_source_dir/sdl_core" "git@github.com:smartdevicelink/sdl_core.git" "origin/develop"
sync_repo "$project_source_dir/sdl_atf" "git@github.com:smartdevicelink/sdl_atf.git" "origin/develop"
sync_repo "$project_source_dir/sdl_atf_test_scripts" "git@github.com:smartdevicelink/sdl_atf_test_scripts.git" "origin/develop"
sync_repo "$project_source_dir/sdl_hmi" "git@github.com:smartdevicelink/sdl_hmi.git" "origin/develop"
sync_repo "$project_source_dir/sdl_infrastructure" "git@github.com:EKuliiev/sdl_infrastructure.git" "origin/master"
