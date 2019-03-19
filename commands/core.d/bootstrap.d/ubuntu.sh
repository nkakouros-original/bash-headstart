#!/usr/bin/env bash

distro_pacman="${distro_pacman:-sudo apt-get install -y}"

distro_packages+=(
  "python3"
  "python3-pip"
)

pip_packages+=(
  # 'python-gilt'
  'git+git://github.com/tterranigma/gilt@remotes'
)

info "checking required tools and libraries..."

$distro_pacman "${distro_packages[@]}"

info "installing Python 3 dependencies..."

sudo pip3 install "${pip_packages[@]}"
