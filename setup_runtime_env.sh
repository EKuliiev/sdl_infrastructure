#!/bin/bash

# This script MUST be sourced
if [[ $_ != $0 ]]
then
    if [ -n "$ZSH_VERSION" ]; then
        this_script_location="$( dirname $( realpath -s ${(%):-%N} ) )"
        #echo "assume Zsh"
    elif [ -n "$BASH_VERSION" ]; then
        this_script_location="$( dirname $( realpath -s ${BASH_SOURCE[0]} ) )"
        #echo "assume Bash"
    else
        this_script_location="$(cd "$(dirname "${__dir}")" && pwd)"
        #echo "$(basename ${__file} .sh)"
    fi
    
    # echo "this_script_location: $this_script_location"
    
    source $this_script_location/helpers.sh
    
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
    
    export THIRD_PARTY_INSTALL_PREFIX=$project_third_party_dir
    export THIRD_PARTY_INSTALL_PREFIX_ARCH=$project_third_party_dir/$( uname -i )
    
    export LD_LIBRARY_PATH=$(add_path_to_var "$LD_LIBRARY_PATH" "$THIRD_PARTY_INSTALL_PREFIX/lib")
    export LD_LIBRARY_PATH=$(add_path_to_var "$LD_LIBRARY_PATH" "$THIRD_PARTY_INSTALL_PREFIX_ARCH/lib")
    echo " ---> LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
else
    echo " ---> This script MUST be sourced!"
fi
