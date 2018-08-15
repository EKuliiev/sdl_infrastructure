#!/bin/bash

source $( dirname $( realpath -s $0 ) )/helpers.sh

build_type="release"
perform_clean=false
perform_install=false
build_unittest=false
install_prefix_path=$project_binary_dir

show_usage_and_exit()
{
if [ -n "$1" ]
then
    printf "$1\n\n"
fi

readonly local scriptname=`basename "$0"`;

for cmake_gen in "${!cmake_ide_generators[@]}"
do
    cmake_gen_list+="$cmake_gen, "
done

echo "usage: $scriptname [-h, --help] [--buildtype BUILD_TYPE] [-c, --clean] [-i, --install]  [--install-prefix PREFIX_PATH]
    [--with-tests] [--cmakearg CMAKE_ARG_LIST] [--ide-generator IDE_GENERATOR]

    <<< OpenSDL: SDL Core Build Options >>>

optional arguments:
  -h, --help                  Show this help message and exit
  -i, --install               Perform install.
  --install-prefix            Specify install prefix path(default $install_prefix_path)
  --buildtype                 Specify build mode([release, debug], default: $build_type)
  -c, --clean                 Clean all previous downloads and built directories
  --with-tests                Build unit tests
  --cmakearg                  Pass additional arguments directly to cmake.
  --ide-generator             Specify generator to produce project files for an specific IDE
                              from the list [${cmake_gen_list::-2}].

example:
./$scriptname --install --cmakearg \"-DEXTENDED_POLICY=PROPRIETARY\" --ide-generator $cmake_gen
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
        --buildtype             ) ((EndOpt)) && args[$i]="$1" || args[$i]="-b";;
        --install               ) ((EndOpt)) && args[$i]="$1" || args[$i]="-i";;
        --install-prefix        ) ((EndOpt)) && args[$i]="$1" || args[$i]="-p";;
        --with-tests            ) ((EndOpt)) && args[$i]="$1" || args[$i]="-u";;
        --cmakearg              ) ((EndOpt)) && args[$i]="$1" || args[$i]="-a";;
        --ide-generator         ) ((EndOpt)) && args[$i]="$1" || args[$i]="-g";;
        # default case : short option use the first char of the long option:
        --?*                    ) ((EndOpt)) && args[$i]="$1" || args[$i]="-${1:2:1}";;
        # pass through anything else:
        *                       ) args[$i]="$1" ;;
    esac
    shift
done
# reset the translated args
set -- "${args[@]}"

readonly options='hcip:b:ua:g:'
while getopts $options opt; do
    case "$opt" in
        h) show_usage_and_exit ;;
        c) perform_clean=true;
           echo " ---> Building with clean requested" ;;
        b) build_type=$OPTARG;
           echo " ---> Build type specified: $build_type" ;;
        i) perform_install=true;
           echo " ---> Installing requested." ;;
        p) install_prefix_path=$OPTARG;
           echo " ---> Install prefix path specified: $install_prefix_path" ;;
        u) build_unittest=true;
           echo " ---> Building unit tests requested." ;;
        a) add_cmake_arg=$OPTARG;
           echo " ---> Additional cmake options: \"$add_cmake_arg\"" ;;
        g) cmake_ide_generator=$OPTARG;
           echo " ---> Generating project files for IDE \"$cmake_ide_generator\" requested" ;;
        \? ) echo "Unknown option: -$OPTARG" >&2; exit 1;;
        :  ) echo "Missing option argument for -$OPTARG" >&2; exit 1;;
        *  ) echo "Unrecognized option: -$OPTARG" >&2; exit 1;;
      esac
done
shift $(( OPTIND - 1 ))

trap 'on_abort "Build SDL_CORE FAILED"' ERR
trap 'on_abort "Build SDL_CORE INTERRUPTED"' SIGTERM SIGINT
trap 'on_abort "Build SDL_CORE TERMINATED"' SIGQUIT SIGTERM
trap 'on_success "Building SDL_CORE successfully finished"' EXIT

on_startup "Building SDL_CORE .."


set -e

echo "Project source dir:      $sdl_core_source_dir"
echo "Project binary dir:      $project_binary_dir"
echo "Project install dir:     $install_prefix_path"
echo "Project third party dir: $project_third_party_dir"

mkdir -vp $project_binary_dir
mkdir -vp $project_third_party_dir

export THIRD_PARTY_INSTALL_PREFIX=$project_third_party_dir
export THIRD_PARTY_INSTALL_PREFIX_ARCH=$project_third_party_dir/$( uname -i )

if [ $perform_clean = "true" ]
then
    # CAUTION be careful while specifying dir to remove
    clean_directory $project_binary_dir
fi

cmake_args+=" -DCMAKE_INSTALL_PREFIX=$install_prefix_path "

if [ $build_unittest = "true" ]
then
    export ENABLE_TESTS=TESTS_ON
else
    export ENABLE_TESTS=TESTS_OFF
fi

# enable logging
export ENABLE_LOG=LOG_ON

if [ $build_type = "release" ]
then
    cmake_args+=' -DCMAKE_BUILD_TYPE=Release '
elif [ $build_type = "debug" ]
then
    cmake_args+=' -DCMAKE_BUILD_TYPE=Debug '
else
    echo " ---> Couldn't recognize build type '$build_type'"
    echo " ---> 'Debug' build type Will be used"
    cmake_args+=' -DCMAKE_BUILD_TYPE=Debug '
fi

if ! [ -z ${add_cmake_arg+x} ]
then
    cmake_args+=" $add_cmake_arg "
fi

if ! [ -z ${cmake_ide_generator+x} ]
then
    cmake_args+=" -G\"${cmake_ide_generators[$cmake_ide_generator]}\" "
fi

if [ -f $project_binary_dir/CMakeCache.txt ]
then
    make_args+=-j`nproc`
else
    # Set one thread for initial build
    # Temporary because of wrong dependencies build fails with multithreaded make mode
    make_args+=-j1
fi

if [ $perform_install = "true" ]
then
    make_args+=" install "
fi

cd $project_binary_dir

command_to_perform="cmake $cmake_args $sdl_core_source_dir"
echo " ---> Running '$command_to_perform'" 
eval $command_to_perform

command_to_perform="cmake --build $project_binary_dir -- $make_args"
echo " ---> Running '$command_to_perform'" 
eval $command_to_perform

cd -
