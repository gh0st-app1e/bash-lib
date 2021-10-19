#!/usr/bin/env bash


#######################################
# Check if a path is absolute.
# Arguments:
#   Path to check
# Returns:
#   0 - if the path is absolute
#   non-zero - otherwise
#######################################
# TODO: check if it is a valid path at all (characters, etc).
bl::file::is_absolute_path() {
  local -r path="$1"

  [[ "${path}" = /* ]]
  return $?
}
