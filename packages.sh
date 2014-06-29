#!/bin/bash -e

# Install sudo as root
#   apt-get install sudo
#   addduser alex sudo
#
# For passwordless sudo use visudo to edit /etc/sudoers and 
# add the line
#   alex   ALL = (ALL) NOPASSWD: ALL

sudo echo "Testing sudo installed"

echo "Installing quake"
sudo apt-get install guake 
echo "Installing guake schema manually"
gconftool-2 --install-schema-file=/usr/share/gconf/schemas/guake.schemas

echo "Installing exuberant-ctags"
sudo apt-get install exuberant-ctags

echo "Installing vim"
sudo apt-get install vim

echo "Installing curl"
sudo apt-get install curl

echo "Installing tmux dependencies"
sudo apt-get install libevent-dev libncurses-dev pkg-config
echo "Now build tmux from source"

