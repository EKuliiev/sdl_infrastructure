#!/bin/bash

#!/bin/bash

source $( dirname $( realpath -s $0 ) )/helpers.sh

trap 'on_abort "Loading SDL components FAILED"' ERR SIGQUIT SIGTERM SIGINT
trap 'on_success "Loading SDL components successfully finished"' EXIT

on_startup "Loading SDL components .."

load_type="https"

set -e

show_usage_and_exit()
{
if [ -n "$1" ]
then
    printf "$1\n\n"
fi

readonly local scriptname=`basename "$0"`;

echo "usage: $scriptname [-h, --help] [--ssh]

    <<< SDL Core Sync Options >>>

optional arguments:
  -h, --help                  Show this help message and exit
  --ssh                       Load using ssh for Open SDL (make sure you are able to work via ssh).
                              By default: $load_type.
"
    exit 0;
}

for ((i=1;$#;i++)) ; do
    case "$1" in
        --                      ) EndOpt=1 ;;&
        --help                  ) ((EndOpt)) && args[$i]="$1" || args[$i]="-h";;
        --ssh                   ) ((EndOpt)) && args[$i]="$1" || args[$i]="-s";;
        # default case : short option use the first char of the long option:
        --?*                    ) ((EndOpt)) && args[$i]="$1" || args[$i]="-${1:2:1}";;
        # pass through anything else:
        *                       ) args[$i]="$1" ;;
    esac
    shift
done
# reset the translated args
set -- "${args[@]}"

readonly options='hs'
while getopts $options opt; do
    case "$opt" in
        h) show_usage_and_exit ;;
        s) load_type="ssh";
           echo " ---> Loading via '$load_type'" ;;
        \? ) echo "Unknown option: -$OPTARG" >&2; exit 1;;
        :  ) echo "Missing option argument for -$OPTARG" >&2; exit 1;;
        *  ) echo "Unrecognized option: -$OPTARG" >&2; exit 1;;
      esac
done
shift $(( OPTIND - 1 ))

echo "Project root source dir: $project_source_dir"

if [ $load_type == "ssh" ]
then
    sync_repo "$project_source_dir/sdl_infrastructure" "git@github.com:EKuliiev/sdl_infrastructure.git" "origin/master"
    sync_repo "$project_source_dir/sdl_core" "git@github.com:smartdevicelink/sdl_core.git" "origin/develop"
    sync_repo "$project_source_dir/sdl_atf" "git@github.com:smartdevicelink/sdl_atf.git" "origin/develop"
    sync_repo "$project_source_dir/sdl_atf_test_scripts" "git@github.com:smartdevicelink/sdl_atf_test_scripts.git" "origin/develop"
    sync_repo "$project_source_dir/sdl_hmi" "git@github.com:smartdevicelink/sdl_hmi.git" "origin/develop"
else
    sync_repo "$project_source_dir/sdl_atf" "https://github.com/EKuliiev/sdl_infrastructure.git" "origin/master"
    sync_repo "$project_source_dir/sdl_core" "https://github.com/smartdevicelink/sdl_core.git" "origin/develop"
    sync_repo "$project_source_dir/sdl_atf" "https://github.com/smartdevicelink/sdl_atf.git" "origin/develop"
    sync_repo "$project_source_dir/sdl_atf_test_scripts" "https://github.com/smartdevicelink/sdl_atf_test_scripts.git" "origin/develop"
    sync_repo "$project_source_dir/sdl_hmi" "https://github.com/smartdevicelink/sdl_hmi.git" "origin/develop"
fi
