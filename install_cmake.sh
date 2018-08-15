#!/bin/bash

set -e

source $( dirname $( realpath -s $0 ) )/helpers.sh

trap 'on_abort "Installing CMake ABORTED"' ERR SIGQUIT SIGTERM SIGINT
trap 'on_success "Installation CMake successfully finished"' EXIT

on_startup "Installing CMake .."

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

readonly target_name="cmake"
readonly required_version="3.11.4"

# check if exists
target_found=true
cmake --version >/dev/null 2>&1 || { target_found=false; echo " ---> $target_name have NOT been installed."; }

if [ $target_found == "true" ]
then
    readonly target_version=`cmake --version`
    readonly package_version=`echo $target_version | sed "s/^.*cmake version \([0-9.]*\).*/\1/"`

    echo " ---> $target_name found(installed $target_name version $package_version, minimum required $required_version)."
    version_compare_result=$(version_compare $required_version $package_version)
    case $version_compare_result in
      "="|"<") echo " ---> Instalation for $target_name will be SKIPPED."; exit 0 ;;
      ">")   echo " ---> Instalation for $target_name REQUIRED." ;;
    esac
else
    echo " ---> $target_name have NOT been found."
    echo " ---> Instalation for $target_name REQUIRED."
fi

libs_to_install+=" openssl libssl-dev "
echo " ---> Installing required libraries '$libs_to_install' .."
sudo apt install $libs_to_install

echo " ---> Required packages have been successfully installed."

readonly cmake_archive_name="$target_name-$required_version-Linux-x86_64.sh"
required_major_version=`echo $required_version | cut -d. -f1`
required_minor_version=`echo $required_version | cut -d. -f2`

readonly target_link="https://cmake.org/files/v$required_major_version.$required_minor_version/$cmake_archive_name"
readonly load_dir="/tmp"
echo "Loading $target_name archive from $target_link .."
wget --no-check-certificate -P $load_dir $target_link
chmod +x $load_dir/$cmake_archive_name
readonly install_prefix_path="/opt/3dparty"
readonly setenv_filepath="$install_prefix_path/set_env.sh"

sudo mkdir -vp $install_prefix_path/$target_name-$required_version
sudo $load_dir/$cmake_archive_name --skip-license --exclude-subdir --prefix=$install_prefix_path/$target_name-$required_version

rm -f $load_dir/$cmake_archive_name

printf '# !!!This script MUST be sourced\n\n' | sudo tee $setenv_filepath > /dev/null
printf "PATH=$install_prefix_path/$target_name-$required_version/bin:"'$PATH' | sudo tee -a $setenv_filepath > /dev/null
printf '\n\necho PATH=$PATH\n' | sudo tee -a $setenv_filepath > /dev/null

readonly sh_conf_marker="#ser_customized_part"
sh_conf_file=$( readlink -m ~/.zshrc )
if [ -e $sh_conf_file ] && ! grep -Fxq $sh_conf_marker $sh_conf_file
then
    printf "\n\n$sh_conf_marker\n\nsource $setenv_filepath\n" >> $sh_conf_file
    echo " ---> $sh_conf_file updated."
fi

sh_conf_file=$( readlink -m ~/.bashrc )
if [ -e $sh_conf_file ] && ! grep -Fxq $sh_conf_marker $sh_conf_file
then
    printf "\n\n$sh_conf_marker\n\nsource $setenv_filepath\n" >> "$sh_conf_file"
    echo " ---> $sh_conf_file updated."
fi

source $setenv_filepath
echo " ---> CMake $required_version installed."
echo -e " \033[31m---> You should reboot the system to apply changes OR just perform in your current shell 'exec <shell>' where <shell> is bash or zsh, etc.\033[0m"

