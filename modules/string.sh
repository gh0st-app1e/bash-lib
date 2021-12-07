#!/usr/bin/env bash
#
# Helper functions for strings.
#


#######################################
# Check if a string is hexadecimal.
# Arguments:
#   String to check
# Returns:
#   0 - if the string is hexadecimal
#   1 - if the string is not hexadecimal
#######################################
bl::string::is_hexadecimal() {
  local -r value="$1"

  if [[ "${value}" =~ ^[0-9A-Fa-f]{1,}$ ]]; then
    return 0
  else
    return 1
  fi
}
