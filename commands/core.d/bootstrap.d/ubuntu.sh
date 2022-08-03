#!/usr/bin/env bash

distro_pacman="${distro_pacman:-sudo -E apt-get install -y}"

distro_packages+=(
  "python3"
  "python3-pip"
  "gawk"
  'sed'
  'bash-completion'
)

pip_packages+=(
  # 'python-gilt'
  'git+http://github.com/coala/git-url-parse@1.1'
  'git+http://github.com/nkakouros-forks/gilt@all'
)

sudo apt update

info "checking required tools and libraries..."

export DEBIAN_FRONTEND=noninteractive

$distro_pacman "${distro_packages[@]}"

info "installing Python 3 dependencies..."

sudo pip3 install "${pip_packages[@]}"
