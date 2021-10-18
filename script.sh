#!/bin/bash
#
# Helper functions for writing scripts.
#
# Dependencies:
#   - log
#   - os


#######################################
# Ask user a question and expect "yes" or "no" as an answer.
# Ask again until the answer is either "yes" or "no".
# Arguments:
#   Question to ask
# Outputs:
#   The question -> stdout
# Returns:
#   0 - if the answer is "yes"
#   1 - if the answer is "no"
#######################################
bl::script::ask_yes_no() {
  local -r message="${1}"
  local -r choices="(y/N)"

  while true; do
    printf "%s %s\n" "${message}" "${choices}"
    read -r user_input
    case "${user_input}" in
      "y"|"Y")
        return 0
        ;;
      "n"|"N"|"")
        return 1
        ;;
      *)
        ;;
    esac
  done
}

#######################################
# Run a command as root.
# Uses sudo for elevation.
# Returns:
#   The command's exit code - if the command was run
#   Exits with code 1 - if the command was not run
#######################################
bl::script::run_as_root() {
  local -r command="$1"
  if [[ -z "${command}" ]]; then
    bl::log::fatal "No command was provided"
    exit 1
  fi

  # su is not used due to difficulties in passing the arguments correctly.
  if [[ "$(bl::os::euid)" != "0" ]]; then
    if command -v sudo &>/dev/null; then
      sudo -- "$@"
      # sudo returns 1 if there was an error.
      return $?
    else
      bl::log::fatal "sudo is not available"
      exit 1
    fi
  fi
}

#######################################
# Check if running as root.
# If running as another user, elevate and re-run with bl::script::run_as_root().
# Correct usage is at the beginning of the script before any script arguments are modified.
# Arguments:
#   "$@" (script arguments)
# Returns:
#   0 - if already running as root
#   1 - if was unable to re-run as root
#   exits with the script's exit code - if was able to re-run as root
#######################################
# TODO: check for current bash instance's cmdline options and pass them too?
bl::script::root_guard() {
  if [[ "$(bl::os::euid)" != "0" ]]; then
    bl::log::warn "Running as a user other than root. Trying to elevate..."
    bl::script::run_as_root "bash" "$0" "$@"
    exit $?
  fi
}
