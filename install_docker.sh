#!/bin/bash

source $( dirname $( realpath -s $0 ) )/helpers.sh

set -e

trap 'on_abort "Installing Docker ABORTED"' ERR SIGQUIT SIGTERM SIGINT
trap 'on_success "Installation Docker DONE"' EXIT

on_startup "Installing Docker .."

if ! which curl > /dev/null; then
    echo -e "CURL not found. Installing curl.."
    while true
    do
        read -r -p " ---> Are you sure you want to continue (Y/n)?: " choice
        choice=${choice,,} # tolower
        if [[ $choice =~ ^(yes|y| ) ]] || [ -z $choice ]
        then
            sudo apt -y install curl
            break
        elif [[ $choice =~ ^(no|n| ) ]]
        then
            echo " ---> Installing CURL CANCELED."
            exit 1
        else
            echo " ---> Invalid input '$choice'. Please type 'yes' or 'no'"
        fi
    done
fi

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install -y docker-ce
sudo usermod -aG docker $USER

# get access without root privileges to usb transport
echo 'SUBSYSTEM=="usb", GROUP="users", MODE="0666" to /etc/udev/rules.d/90-usbpermission.rules'
sudo sh -c "echo 'SUBSYSTEM==\"usb\", GROUP=\"users\", MODE=\"0666\"' > /etc/udev/rules.d/90-usbpermission.rules"
