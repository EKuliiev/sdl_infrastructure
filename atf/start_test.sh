#!/bin/bash

set -e

[[ $# != 1 ]] && echo "Path to tests MUST be specified" && exit 1

source $( dirname $( dirname $( realpath -s $0 ) ) )/sdl_infrastructure/helpers.sh

source $build_utils_source_dir/setup_runtime_env.sh

ulimit -c unlimited

$sdl_atf_source_dir/run.sh $project_binary_dir/bin $1 $sdl_core_api_dir

