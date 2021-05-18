# Bash Headstart

Bash Headstart is a wrapper around
[go-script-bash](https://github.com/mbland/go-script-bash). In my projects I
found my self creating the same structure and same commands over and over
again. Bash Headstart contains the common parts of these projects.

## How to use
1. Add this repo as a git submodule to your project:
```
git submodule add https://github.com/tterranigma/bash-headstart scripts/vendor bash-headstart -b master
```
2. Run `git submodule init --recursive path/to/bash-headstart-submodule`
3. Copy `headstart-template` to the root of your project and rename it to fit
   your project.
4. Run `eval "$(./renamed-headstart-template env -)"`.
5. You are ready to use the `renamed-headstart-template` command.

## External libraries used:
- [go-script-bash](https://github.com/mbland/go-script-bash)
- [Bash infinity](https://github.com/niieani/bash-oo-framework)
- [Autohook](https://github.com/nkantar/Autohook)


