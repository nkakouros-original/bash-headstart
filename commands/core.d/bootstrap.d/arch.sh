#!/usr/bin/env bash

if which yaourt &>/dev/null; then
  distro_pacman="${distro_pacman:-yaourt -S --noconfirm}"
  distro_update_cmd="${distro_update_cmd:-yaourt -Syyuu --aur --noconfirm --devel}"
elif which paru &>/dev/null; then
  distro_pacman="${distro_pacman:-paru -S --noconfirm}"
  distro_update_cmd="${distro_pacman:-paru -Syyuu --noconfirm}"
else
  distro_pacman="${distro_pacman:-sudo pacman -S --noconfirm}"
  distro_update_cmd="${distro_update_cmd:-sudo pacman -Syyuu --noconfirm}"
fi

distro_packages+=(
  "python"
  "python-pip"
  "awk"
  'sed'
  'bash-completion'
)

pip_packages+=(
  # 'python-gilt'
  'git+git://github.com/nkakouros-forks/gilt@all'
)

info "checking required tools and libraries..."

$distro_pacman "${distro_packages[@]}"

info "installing Python 3 dependencies..."

sudo pip3 install "${pip_packages[@]}"
