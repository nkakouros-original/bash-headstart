#!/usr/bin/env bash

# TODO add set -ueo pipefail until stack trace kicks in
# Path to the project's root directory
declare -gx PROJECT_DIR
cd "${0%/*}" || exit "$_HEADSTART_EC_GENERR"
PROJECT_DIR="$PWD"

# Path to bash-headstart's directory
if [[ "${BASH_SOURCE[0]:0:1}" != '/' ]]; then
  cd "$PWD/${BASH_SOURCE[0]%/*}" || exit "$_HEADSTART_EC_GENERR"
else
  cd "${BASH_SOURCE[0]%/*}" || exit "$_HEADSTART_EC_GENERR"
fi
declare -r -x _HEADSTART_CORE_DIR="$PWD"

cd "$PROJECT_DIR"
# if [[ -v HEADSTART_INSTALLATION_DIR ]]; then
  # TODO make sure this variable is during 'headstart env'
  # pushd "$HEADSTART_INSTALLATION_DIR" >/dev/null || exit 1
# fi

# TODO see if this needed once I turn everything into git modules
# . "$_HEADSTART_CORE_DIR/lib/installation"

# if [[ ! -v HEADSTART_INSTALLATION_DIR ]]; then
  # installation_install >&2
  # <<-CODE_NOTE We are redirecting output to stderr because when running
  #             `eval "$(./headstart env -)"` when first installing the project,
  #             the above script will run and output from it will cause eval to
  #             print errors that the commands like 'Downloading' and 'Download'
  #             do not exist. By redirecting to stderr, we do not have this
  #             problem.
# fi

. "$_HEADSTART_CORE_DIR/headstart-load-libs.bash" "$@" \
  "${_HEADSTART_CORE_DIR#$PROJECT_DIR/}/"{commands,}

declare -gx _HEADSTART_TMP_DIR="${_HEADSTART_TMP_DIR-$PROJECT_DIR/.tmp}"
declare -gx _HEADSTART_VENDOR_DIR="${_HEADSTART_CORE_DIR}/vendor"

declare -gx _HEADSTART_CMD="${_GO_CMD##*/}"
declare -gx _HEADSTART_PROJECT_CONFIG="$PROJECT_DIR/project.conf"
declare -gx _HEADSTART_CORE_LOCK="$PROJECT_DIR/.core.lock"

function headstart() {
  local debug=false
  local verbosity=''
  local -a rest
  local go_early=false
  local print_version=false
  local print_help=false

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -d|--debug)
        debug=true
        ;;
      -v*)
        verbosity="${1#-}"
        ;;
      --version|-V)
        print_version=true
        ;;
      --help|-h)
        print_help=true
        ;;
      complete|env)
      # <<-CODE_NOTE: This is matched when autocompletion occurs or when using
      #               `eval "$(./headstart env -)"`
        go_early=true
        rest+=("$1")
        ;;
      *)
        rest+=("$1")
        ;;
    esac
    shift
  done

  . "$_GO_USE_MODULES" 'installation'

  if [[ "$go_early" == 'true' ]]; then
    case "${rest[0]}" in
      'env')
        @go "${rest[@]}"
        return
        ;;
      'complete')
        if [[ "$(get_installation_status)" == 'bootstrapped' ]]; then
          @go "${rest[@]}"
        fi
        return
        ;;
    esac
  fi
  unset go_early

  . "$_GO_USE_MODULES" 'core' 'aliases' 'project' 'system'

  set_standard_outputs
  set_trace "$debug"
  set_debug_levels "$verbosity"
  unset verbosity
  unset debug

  if [[ "$print_version" == 'true' ]]; then
    printf "$_HEADSTART_CMD version: "
    core_get_installed_version
    echo "$version"
    return
  fi

  if ! installation_check_status; then
    if [[ "${rest[*]}" == 'help core bootstrap' ]]; then
      @go "${rest[@]}"
      return
    elif [[ "${rest[*]}" =~ ^core\ bootstrap$ && "$print_help" == 'true' ]];
    then
      @go help "${rest[@]}"
      return
    elif [[ "${rest[*]}" =~ ^core\ bootstrap\ *$ ]]; then
      @go "${rest[@]}"
      return
    else
      abort "project needs to be bootstrapped first: $_HEADSTART_CMD core bootstrap"
      return
    fi
  fi

  core_check_upgrades

  if [[ "$print_help" == 'true' ]]; then
    @go help "${rest[@]}"
    return
  fi

  # TODO do not explicitly create these. Parse the config and expose the
  # variables in bash-headstart
  declare -gx GCE_PROJECT_NAME
  declare -gx WORLD_REUSE

  # TODO don't rely on this returning empty strings. When first installing,
  # `core bootstrap` will execute this returning nothing. Instead handle that
  # case better and have the function return an error code if it doesn't find
  # what it needs.
  GCE_PROJECT_NAME="$(project_get_gce_project)"
  WORLD_REUSE="$(project_get_world_reuse)"

  if [[ "${rest[@]}" != '' && "${rest[0]}" == 'core' ]]; then
    if [[ "${#rest[@]}" -ge 2 && "${rest[1]}" == 'bootstrap' ]]; then
      @go "${rest[@]}"
      return
    fi
  fi

  @go "${rest[@]}"
}

