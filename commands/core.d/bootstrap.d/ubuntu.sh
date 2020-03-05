#!/usr/bin/env bash

distro_pacman="${distro_pacman:-sudo apt-get install -y}"

distro_packages+=(
  "python3"
  "python3-pip"
  "awk"
  'sed'
  'bash-completion'
)

pip_packages+=(
  # 'python-gilt'
  'git+git://github.com/retr0h/git-url-parse@1.1'
  'git+git://github.com/nkakouros-forks/gilt@all'
)

sudo apt update

info "checking required tools and libraries..."

$distro_pacman "${distro_packages[@]}"

info "installing Python 3 dependencies..."

sudo pip3 install "${pip_packages[@]}"
