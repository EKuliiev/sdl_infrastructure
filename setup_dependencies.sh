#!/bin/bash

source $( dirname $( realpath -s $0 ) )/helpers.sh

set -e

trap 'on_abort "Preparation Preparation Open SDL dependencies FAILED"' ERR SIGQUIT SIGTERM SIGINT
trap 'on_success "Preparation Open SDL dependencies successfully finished"' EXIT

on_startup "Preparation Open SDL dependencies .."

echo " ---> Installing SDL required tools.."
echo " ---> !!!(ROOT PERMISSIONS REQUIRED) Running sudo apt-get update.."
sudo apt-get update || echo " ---> ERROR: Updating list of available packages failed. Remove invalid links."

tools_to_install+=" bluez-tools sqlite3 automake g++ gcc "
echo " ---> ROOT PERMISSIONS REQUIRED: Running sudo apt-get install -y $tools_to_install"
sudo apt-get install -y $tools_to_install

# SDL-core dependencies
echo " ---> Installing CMake >= 3.0.2.. "
$build_utils_source_dir/install_cmake.sh "3.0.2"

libs_to_install+=" libusb-1.0-0-dev libbluetooth3 libbluetooth-dev libudev-dev libavahi-client-dev libsqlite3-dev "
libs_to_install+=" libexpat1-dev qt5-default libqt5websockets5-dev "

# Install exactly libssl version 1.0.*
readonly lsb_release_version=$(lsb_release -rs)
version_compare_result=$(version_compare $lsb_release_version "16.99")
case $version_compare_result in
  "="|"<") libs_to_install+=" libssl-dev=1.0.* ";;
  ">") libs_to_install+=" libssl1.0-dev " ;;
esac

# SDL-ATF dependencies
libs_to_install+=" liblua5.2-dev libxml2-dev "
echo " ---> Installing required libraries.."
echo " ---> ROOT PERMISSIONS REQUIRED: Running sudo apt-get install -y $libs_to_install"
sudo apt-get install -y $libs_to_install
