#!/bin/bash


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
# Check if running as root.
# If running as another user, check if sudo is present.
# If sudo is present, re-run with sudo if user agrees.
# Returns:
#   0 - if running as root
#   2 - if running as another user and was unable to re-run as root
#   exits with the script's exit code - if was able to re-run as root
#######################################
bl::script::root_guard() {
  if [ "$UID" != "0" ]; then
    if command -v sudo &>/dev/null; then
      bl::script::ask_yes_no "This script must be run as root. Try running with sudo?" ||
        return 2
      # This function is expected to be called only from bash scripts, thus calling bash is OK.
      sudo bash "$0" "$@"
      exit $?
    else
      printf "This script must be run as root.\n"
      return 2
    fi
  fi
}
