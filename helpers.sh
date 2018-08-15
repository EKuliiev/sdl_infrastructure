#!/bin/bash

# returns full path to the script that holds the current line of code
this_line_location()
{
    
    if [ -n "$ZSH_VERSION" ]; then
        this_line_location_path="$( dirname $( realpath -s ${(%):-%N} ) )"
    elif [ -n "$BASH_VERSION" ]; then
        this_line_location_path="$( dirname $( realpath -s ${BASH_SOURCE[0]} ) )"
    else
        this_line_location_path="$(cd "$(dirname "${__dir}")" && pwd)"
    fi
    printf $this_line_location_path
}

clean_directory()
{
    local readonly dir_to_clean="$1";
    if [ -d "$dir_to_clean" ] && [ -n "$dir_to_clean" ] && [ "$dir_to_clean" != "/" ]
    then
        echo " ---> Cleaning directory '$dir_to_clean' .."
        rm -rf $dir_to_clean/*
    fi
}

on_abort()
{
    if [ "$#" -eq 0 ]
    then
        echo "Usage: $FUNCNAME message" >&2
        exit 1
    fi

    echo >&2 "
***************************************************
*** ABORTED: $@
***************************************************
"
    trap : 0
    exit 1
}

on_startup()
{
    if [ "$#" -eq 0 ]
    then
        echo "Usage: $FUNCNAME message" >&2
        exit 1
    fi

    echo "
***********************************************
*** STARTUP: $@
***********************************************"
}

on_success()
{
    local readonly rv=$?
    if [ "$#" -eq 0 ]
    then
        echo "Usage: $FUNCNAME message" >&2
        exit 1
    fi

    if [ $rv -ne 0 ]
    then
        on_abort $@
    fi

    echo "
***********************************************
*** DONE: $@
***********************************************
"
    trap : 0
    exit $rv
}

sync_repo()
{
    if [ "$#" -ne 3 ]; then
        echo "#usage sync_repo <work_dir> <link> <hash>"
        return -1
    fi
    
    local repo_work_dir=$1
    local repo_link=$2
    local repo_hash=$3

    echo " ---> Repo dir '$repo_work_dir', repo link '$repo_link', repo hash '$repo_hash'"

    if ! [ -d $repo_work_dir ]
    then 
       git -C "$( dirname $repo_work_dir )" clone $repo_link || return -1
    fi

    local git_branch_name=$( echo "$repo_hash" | rev | cut -d"/" -f1 | rev )
    if [[ $( git -C $repo_work_dir merge-base $repo_hash $repo_hash ) == $repo_hash* ]]
    then
      # SHA1 were passed
      git_branch_name="tmp"
    fi

    git -C $repo_work_dir checkout -B $git_branch_name || return -1
    git -C $repo_work_dir fetch --all --prune || return -1
    git -C $repo_work_dir reset --hard $repo_hash || return -1
    git -C $repo_work_dir submodule update --init || return -1
}

declare -A cmake_ide_generators
cmake_ide_generators=(
    ["codeblocks"]="CodeBlocks - Unix Makefiles"
    ["codelite"]="CodeLite - Unix Makefiles"
    ["sublime"]="Sublime Text 2 - Unix Makefiles"
    ["kate"]="Kate - Unix Makefiles"
    ["eclipse"]="Eclipse CDT4 - Unix Makefiles" )

project_source_dir=$( dirname $( this_line_location ) )
project_third_party_dir=$project_source_dir/3rd_party
sdl_core_source_dir=$project_source_dir/sdl_core
project_binary_dir="$(dirname $sdl_core_source_dir)/build_$(basename $sdl_core_source_dir)"
build_utils_source_dir=$project_source_dir/sdl_infrastructure
sdl_atf_source_dir=$project_source_dir/sdl_atf
sdl_atf_test_scripts_source_dir=$project_source_dir/sdl_atf_test_scripts

sdl_core_api_dir="$sdl_core_source_dir/src/components/interfaces"
