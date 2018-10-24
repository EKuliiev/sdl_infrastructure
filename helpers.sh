#!/bin/bash

# returns full path to the script that holds the current line of code
this_line_location() {
    if [ -n "$ZSH_VERSION" ]
    then
        this_line_location_path="$( dirname $( realpath -s ${(%):-%x} ) )"
    elif [ -n "$BASH_VERSION" ]
    then
        this_line_location_path="$( dirname $( realpath -s ${BASH_SOURCE[0]} ) )"
    else
        echo "Shell interpreter does NOT supported. Use bash or zsh."
        exit 1
    fi
    printf $this_line_location_path
}

# version_compare <v1> <v2> function
# "=" if equal
# ">" if v1 greater than v2
# "<" if v1 less than v2
version_compare () {
    if [[ $1 == $2 ]]
    then
        printf "="
        return 0;
    fi

    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            printf ">"
            return 0;
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            printf "<"
            return 0;
        fi
    done

    printf "="
    return 0;
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

# usage: cur_user_has_write_permissions <dir_to_check>"
cur_user_has_write_permissions()
{
    if [ "$#" -ne 1 ]
    then
        printf "false";
        return -1;
    fi

    local directory_to_check=$1
    if [ -w $directory_to_check ]
    then
        printf "true"
    else
        printf "false"
    fi

    return 0
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

# add_path <var> <path_to_add> [after]
add_path_to_var()
{
    if ! [ $1 ]
    then
        printf "$2"
    else
        if ! echo "$1" | grep -Eq "(^|:)$2($|:)"
        then
            if [ "$3" = "after" ]
            then
                printf "$1:$2"
            else
                printf "$2:$1"
            fi
        else
            printf "$1"
        fi
    fi
}

typeset -A cmake_ide_generators
cmake_ide_generators["codeblocks"]="CodeBlocks - Unix Makefiles"
cmake_ide_generators["codelite"]="CodeLite - Unix Makefiles"
cmake_ide_generators["sublime"]="Sublime Text 2 - Unix Makefiles"
cmake_ide_generators["kate"]="Kate - Unix Makefiles"
cmake_ide_generators["eclipse"]="Eclipse CDT4 - Unix Makefiles"

project_source_dir=$( dirname $( this_line_location ) )
project_third_party_dir=$project_source_dir/3rd_party
sdl_core_source_dir=$project_source_dir/sdl_core
project_binary_dir="$(dirname $sdl_core_source_dir)/build_$(basename $sdl_core_source_dir)"
build_utils_source_dir=$project_source_dir/sdl_infrastructure
sdl_atf_source_dir=$project_source_dir/sdl_atf
sdl_atf_test_scripts_source_dir=$project_source_dir/sdl_atf_test_scripts

sdl_core_api_dir="$sdl_core_source_dir/src/components/interfaces"
