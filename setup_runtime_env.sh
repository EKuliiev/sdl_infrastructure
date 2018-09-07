#!/bin/bash

# This script MUST be sourced
if [[ $( readlink -m "$_" ) != $( readlink -m "$0" ) ]]
then
    if [ -n "$ZSH_VERSION" ]
    then
        this_script_location="$( dirname $( realpath -s ${(%):-%x} ) )"
    elif [ -n "$BASH_VERSION" ]
    then
        this_script_location="$( dirname $( realpath -s ${BASH_SOURCE[0]} ) )"
    else
        echo "Shell interpreter does NOT supported. Use bash or zsh."
        exit 1
    fi

    # exports add_path_to_var function
    # exports project_third_party_dir
    source $this_script_location/helpers.sh

    export THIRD_PARTY_INSTALL_PREFIX=$project_third_party_dir
    export THIRD_PARTY_INSTALL_PREFIX_ARCH=$project_third_party_dir/$( uname -i )
    
    export LD_LIBRARY_PATH=$(add_path_to_var "$LD_LIBRARY_PATH" "$THIRD_PARTY_INSTALL_PREFIX/lib")
    export LD_LIBRARY_PATH=$(add_path_to_var "$LD_LIBRARY_PATH" "$THIRD_PARTY_INSTALL_PREFIX_ARCH/lib")
    echo " ---> LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
else
    echo " ---> This script MUST be sourced!"
fi
