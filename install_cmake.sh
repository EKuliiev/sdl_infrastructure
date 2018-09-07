#!/bin/bash

[[ $# != 1 ]] && echo "usage: $( basename "$0" ) <cmake-version>. (for instance: $( basename "$0" ) 3.11.4)" && exit 1

readonly package_name="cmake"
readonly required_version=$1

set -e

source $( dirname $( realpath -s $0 ) )/helpers.sh

trap 'on_abort "Installing CMake ABORTED"' ERR SIGQUIT SIGTERM SIGINT
trap 'on_success "Installation CMake successfully finished"' EXIT

on_startup "Installing CMake .."

# check if exists
target_found=true
cmake --version >/dev/null 2>&1 || { target_found=false; echo " ---> $package_name have NOT been installed."; }

if [ $target_found == "true" ]
then
    readonly target_version=`cmake --version`
    readonly package_version=`echo $target_version | sed "s/^.*cmake version \([0-9.]*\).*/\1/"`

    echo " ---> $package_name found(installed $package_name version $package_version, minimum required $required_version)."
    version_compare_result=$(version_compare $required_version $package_version)
    case $version_compare_result in
      "="|"<") echo " ---> Instalation for $package_name will be SKIPPED."; exit 0 ;;
      ">")   echo " ---> Instalation for $package_name REQUIRED." ;;
    esac
else
    echo " ---> $package_name have NOT been found."
    echo " ---> Instalation for $package_name REQUIRED."
fi

# Check in standart repositories
readonly apt_version=`apt-cache show cmake | grep Version | head -1 | sed "s/^.*Version: \([0-9.]*\).*/\1/"`
compare_result=$(version_compare $apt_version $required_version)
case $compare_result in
    "<")
        echo " ---> Available $package_name version from standard repositories: '$apt_version' but required: '$required_version'";;
    "="|">")
        echo " ---> Installing $package_name from standart repositories.."
        tools_to_install=" cmake "
        sudo apt install -y $tools_to_install
        echo "$package_name have been successfully installed!";
        exit 0; ;;
esac

libs_to_install+=" openssl libssl1.0-dev "
echo " ---> Installing required libraries '$libs_to_install' .."
sudo apt install -y $libs_to_install

echo " ---> Required packages have been successfully installed."

readonly cmake_archive_name="$package_name-$required_version-Linux-x86_64.sh"
required_major_version=`echo $required_version | cut -d. -f1`
required_minor_version=`echo $required_version | cut -d. -f2`

readonly target_link="https://cmake.org/files/v$required_major_version.$required_minor_version/$cmake_archive_name"
readonly load_dir="/tmp"
echo "Loading $package_name archive from $target_link .."
wget --no-check-certificate -P $load_dir $target_link
chmod +x $load_dir/$cmake_archive_name
readonly install_prefix_path="/opt/3dparty"
readonly setenv_filepath="$install_prefix_path/set_env.sh"

sudo mkdir -vp $install_prefix_path/$package_name-$required_version
sudo $load_dir/$cmake_archive_name --skip-license --exclude-subdir --prefix=$install_prefix_path/$package_name-$required_version

rm -f $load_dir/$cmake_archive_name

printf '# !!!This script MUST be sourced\n\n' | sudo tee $setenv_filepath > /dev/null
printf "PATH=$install_prefix_path/$package_name-$required_version/bin:"'$PATH' | sudo tee -a $setenv_filepath > /dev/null
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
