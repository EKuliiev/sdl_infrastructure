#!/bin/bash

source $( dirname $( realpath -s $0 ) )/helpers.sh

perform_clean=false

show_usage_and_exit()
{
if [ -n "$1" ]
then
    printf "$1\n\n"
fi

readonly local scriptname=$( basename "$0" );

for cmake_gen in "${!cmake_ide_generators[@]}"
do
    cmake_gen_list+="$cmake_gen, "
done

echo "usage: $scriptname [-h, --help] [-c, --clean]

    <<< Preparation ATF Options >>>

optional arguments:
  -h, --help                  Show this help message and exit
  -c, --clean                 Clean built directory (temporary does NOT supported)

example:
./$scriptname
"

    exit 0;
}

# translate long options to short
# Note: This enable long options but disable "--?*" in $OPTARG, or disable long options after  "--" in option fields.
for ((i=1;$#;i++)) ; do
    case "$1" in
        --                      ) EndOpt=1 ;;&
        --help                  ) ((EndOpt)) && args[$i]="$1" || args[$i]="-h";;
        --clean                 ) ((EndOpt)) && args[$i]="$1" || args[$i]="-c";;
        # default case : short option use the first char of the long option:
        --?*                    ) ((EndOpt)) && args[$i]="$1" || args[$i]="-${1:2:1}";;
        # pass through anything else:
        *                       ) args[$i]="$1" ;;
    esac
    shift
done
# reset the translated args
set -- "${args[@]}"

readonly options='hc'
while getopts $options opt; do
    case "$opt" in
        h) show_usage_and_exit ;;
        c) perform_clean=true;
           echo " ---> Building with clean requested." ;;
        \? ) echo "Unknown option: -$OPTARG" >&2; exit 1;;
        :  ) echo "Missing option argument for -$OPTARG" >&2; exit 1;;
        *  ) echo "Unrecognized option: -$OPTARG" >&2; exit 1;;
      esac
done
shift $(( OPTIND - 1 ))

trap 'on_abort "Preparation ATF FAILED"' ERR
trap 'on_abort "Preparation ATF INTERRUPTED"' SIGTERM SIGINT
trap 'on_abort "Preparation ATF TERMINATED"' SIGQUIT SIGTERM
trap 'on_success "Preparation ATF successfully finished"' EXIT

on_startup "Preparation ATF .."

set -e

echo " ---> Checking submodules for $sdl_atf_source_dir.."
git -C $sdl_atf_source_dir submodule update --init

cp -vf $sdl_core_source_dir/src/components/interfaces/HMI_API.xml $sdl_atf_source_dir/data
cp -vf $sdl_core_source_dir/src/components/interfaces/MOBILE_API.xml $sdl_atf_source_dir/data

$build_utils_source_dir/build_atf.sh

readonly sdl_atf_binary_dir=$sdl_atf_source_dir

cp -vf $build_utils_source_dir/atf/start_test.sh $sdl_atf_binary_dir
sed -i "s|PROJECT_SOURCE_DIR|${project_source_dir}|g" $sdl_atf_binary_dir/start_test.sh

ln -sf $sdl_atf_test_scripts_source_dir/files $sdl_atf_binary_dir
ln -sf $sdl_atf_test_scripts_source_dir/test_scripts $sdl_atf_binary_dir
ln -sf $sdl_atf_test_scripts_source_dir/user_modules $sdl_atf_binary_dir
ln -sf $sdl_atf_test_scripts_source_dir/test_sets $sdl_atf_binary_dir
