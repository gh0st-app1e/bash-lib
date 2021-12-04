#!/usr/bin/env bash
#
# Functions related to handling files.
#
# Dependencies:
#   - log


#######################################
# Get absolute path for a file/dir.
# Taken from https://stackoverflow.com/a/23002317.
# Arguments:
#   Path - Relative/absolute, must exist and 
#          be accessible by the current user
# Outputs:
#   Absolute path
# Returns:
#   0 - if successful
#   non-zero - otherwise
#######################################
bl::file::abs_path() {
  local -r path="$1"

  local abspath
  if [[ -d "${path}" ]]; then
    # The path is a directory.
    abspath="$(cd "${path}" || exit 1; pwd)" || return 1
  elif [[ -e "${path}" ]]; then
    # The path is a file.
    if [[ "${path}" == /* ]]; then
      abspath="${path}"
    elif [[ "${path}" == */* ]]; then
      dirname="$(cd "${path%/*}" || exit 1; pwd)" || return 1
      basename="${path##*/}"
      abspath="${dirname}/${basename}"
    else
      # The file is in the current directory.
      abspath="$(pwd)/${path}"
    fi
  else
    # Path does not exist.
    return 1
  fi
  echo "${abspath}"
}


#######################################
# Check if a path is absolute.
# Arguments:
#   Path to check
# Returns:
#   0 - if the path is absolute
#   non-zero - otherwise
#######################################
# TODO: check if it is a valid path at all (characters, etc).
bl::wip::is_absolute_path() {
  local -r path="$1"

  [[ "${path}" = /* ]]
  return $?
}


#######################################
# Extract files from an archive.
# Arguments:
#   Archive to extract
#   Destintaion directory
# Returns:
#   0 - if extracted successfully
#   non-zero - otherwise
#######################################
bl::wip::extract() {
  local -r archive="${1}"
  local -r destination="${2}"
  
  if [[ ! -d "${destination}" ]]; then
    mkdir -p "${destination}"
  fi
  if [[ -f "${archive}" ]]; then
    case "${archive}" in
      *.tar)      tar xf   "${archive}" -C "${destination}" --strip-components 1 ;;
      *.tgz)      tar xzf  "${archive}" -C "${destination}" --strip-components 1 ;;
      *.tar.gz)   tar xzf  "${archive}" -C "${destination}" --strip-components 1 ;;
      *.tbz2)     tar xjf  "${archive}" -C "${destination}" --strip-components 1 ;;
      *.tar.bz2)  tar xjf  "${archive}" -C "${destination}" --strip-components 1 ;;
      *.tar.xz)   tar xJf "${archive}" -C "${destination}" --strip-components 1 ;;
      *)
        bl::log::error "'${archive}' cannot be extracted with extract()"
        return 1
        ;;
    esac
  else
    bl::log::error "'${archive}' is not a valid file"
    return 2
  fi
}
