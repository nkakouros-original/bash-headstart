#!/usr/bin/env bash

# TODO add set -ueo pipefail until stack trace kicks in

# The code below is not in a function as variables, functions, etc defined here
# and in the sourced files need to be accessible in the global scope.

# Path to the project's root directory
declare -gx PROJECT_DIR

# Used for testing
if [[ -v PROJECT_DIR ]]; then
  PROJECT_DIR="$PROJECT_DIR"
else
  cd "${0%/*}" || exit "$_HEADSTART_EC_GENERR"
  PROJECT_DIR="$PWD"
fi

if [[ ! -v _HEADSTART_SCRIPT_NAME ]]; then  # tests may set this directly
  declare -gx _HEADSTART_SCRIPT_NAME="${0##*/}"
fi

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


tmp_dir="${_HEADSTART_SCRIPT_NAME~~}_TMP_DIR"
declare -gx _HEADSTART_TMP_DIR="${!tmp_dir}"
declare -gx _HEADSTART_VENDOR_DIR="${_HEADSTART_CORE_DIR}/vendor"

declare -gx HEADSTART_RESOURCES_DIR="${HEADSTART_RESOURCES_DIR-resources}"
declare -gx _HEADSTART_CMD="${_GO_CMD##*/}"
declare -gx _HEADSTART_PROJECT_CONFIG="${HEADSTART_PROJECT_CONFIG-data/config/project.conf}"
declare -gx _HEADSTART_CORE_LOCK="${HEADSTART_CORE_LOCK-data/config/.core.lock}"

declare -x _GO_HELP_HIJACK=true
declare -x GO_TAB_COMPLETIONS_PATTERN=''

. "$_GO_USE_MODULES" 'core'

core_get_installed_version
core_parse_project_config

function headstart() {
  local trace=false
  local debug=false
  local verbosity=''
  local -a rest
  local go_early=false
  local print_version=false
  local print_help=false

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -d | --trace)
        trace=true
        ;;
      -dd | --debug)
        debug=true
        ;;
      -v*)
        verbosity="${1#-}"
        ;;
      --version | -V)
        print_version=true
        ;;
      complete | env)
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

  # This was originally in headstart-load-libs (as all uses of `import`) but
  # was moved here in order to put the trace behind the `-d` cli option.
  if [[ "$trace" == 'true' && "${_GO_BATS_DIR-unset}" == 'unset' ]]; then
    import util/exception
  fi
  # When we are testing the project's code, we want for instance to check that
  # a function returns with a specific code in case of an error. In these cases,
  # we do not want this error code to trigger the stack trace that the
  # `util/exception` code prints as it would pollute the test output. So, we
  # only import this module when not testing. To check if we are in test mode or
  # not, we check the existence of a variable that is set only when testing. We
  # chose randomly `_GO_BATS_DIR` that is set in `devel/test`.

  . "$_GO_USE_MODULES" 'installation' 'aliases'

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

  . "$_GO_USE_MODULES" 'system'

  set_standard_outputs
  set_trace "$debug"
  set_debug_levels "$verbosity"
  unset verbosity
  unset debug

  if [[ "$print_version" == 'true' ]]; then
    printf "$_HEADSTART_CMD version: "
    eval "echo \$${_HEADSTART_SCRIPT_NAME~~}_VERSION"
    return
  fi

  if ! installation_check_status; then
    if [[ "${rest[*]}" == 'help core bootstrap' ]]; then
      @go "${rest[@]}"
      return
    elif [[ "${rest[*]}" =~ ^core\ bootstrap\ ?.*$ && "$print_help" == 'true' ]]; then
      @go help "${rest[@]}"
      return
    elif [[ "${rest[*]}" =~ ^core\ bootstrap\ ?.*$ ]]; then
      @go "${rest[@]}"
      return
    else
      abort "project needs to be bootstrapped first: $_HEADSTART_CMD core bootstrap"
      return
    fi
  fi

  core_check_upgrades

  @go "${rest[@]}"
}
