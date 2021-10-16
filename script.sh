#!/bin/bash

#######################################
# Write a message to stderr.
# Globals:
#   None
# Arguments:
#   Message
# Outputs:
#   Provided message -> stderr
#######################################
bl::script::print_to_stderr() {
  local -r text_to_print="${1:?[!] The text to print is not specified"
  printf '%b' "${text_to_print}" >&2
}

#######################################
# Ask user a question and expect "yes" or "no" as an answer.
# Ask again until the answer is either "yes" or "no".
# Arguments:
#   Question to ask
# Outputs:
#   The question -> stdout
# Returns:
#   0 if the answer is "yes", 1 if "no".
#######################################
bl::script::ask_yes_no() {
  local -r message="${1}"
  local -r choices="(y/N)"

  while true; do
    printf "%s %s\n" "${message}" "${choices}"
    read user_input
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



# TODO:
bl::script::root_guard() {
  if [ "$UID" != "0" ]; then
    printf "[!] This script must be run as root."
    if command -v sudo &>/dev/null; then
      printf " Trying to re-run with sudo...\n"
      sudo "$0" "$@"
      exit
    else
      printf " Exiting...\n"
      exit
  fi
}
