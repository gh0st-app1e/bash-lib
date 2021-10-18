#!/usr/bin/env bash
#
# Functions for interacting with OS.
#
# Dependencies:
#   - log
#   - script


#######################################
# Get current EUID.
# Outputs:
#   EUID -> stdout
# Returns:
#   0
#######################################
bl::os::euid() {
  id -u
}

#######################################
# Get current EGID.
# Outputs:
#   EGID -> stdout
# Returns:
#   0
#######################################
bl::os::egid() {
  id -g
}

#######################################
# Check if a user exists.
# Arguments:
#   Username/UID
# Returns:
#   0 - if the user exists
#   non-zero - otherwise
#######################################
bl::os::user_exists() {
  local -r user="$1"

  getent passwd "${user}" &>/dev/null
  return $?
}

#######################################
# Check if a group exists.
# Arguments:
#   Group name/GID
# Returns:
#   0 - if the group exists
#   non-zero - otherwise
#######################################
bl::os::group_exists() {
  local -r group="$1"

  getent group "${group}" &>/dev/null
  return $?
}

#######################################
# Get UID by username.
# Arguments:
#   Username
# Outputs:
#   UID -> stdout
# Returns:
#   0 - if the user exists
#   non-zero - otherwise
#######################################
bl::os::get_uid_by_username() {
  local -r username="$1"

  getent passwd "${username}" | cut -d: -f3
  return $?
}

#######################################
# Get GID by group name.
# Arguments:
#   Group name
# Outputs:
#   GID -> stdout
# Returns:
#   0 - if the group exists
#   non-zero - otherwise
#######################################
bl::os::get_gid_by_group_name() {
  local -r groupname="$1"

  getent group "${groupname}" | cut -d: -f3
  return $?
}

#######################################
# Get username by UID.
# Arguments:
#   UID
# Outputs:
#   Username -> stdout
# Returns:
#   0 - if the user exists
#   non-zero - otherwise
#######################################
bl::os::get_username_by_uid() {
  local -r uid="$1"

  getent passwd "${uid}" | cut -d: -f1
  return $?
}

#######################################
# Get group name by GID.
# Arguments:
#   GID
# Outputs:
#   Group name -> stdout
# Returns:
#   0 - if the group exists
#   non-zero - otherwise
#######################################
bl::os::get_group_name_by_gid() {
  local -r gid="$1"

  getent group "${gid}" | cut -d: -f1
  return $?
}

#######################################
# Get primary GID by username.
# Arguments:
#   Username
# Outputs:
#   GID -> stdout
# Returns:
#   0 - if the user exists
#   non-zero - otherwise
#######################################
bl::os::get_primary_gid_by_username() {
  local -r username="$1"

  getent passwd "${username}" | cut -d: -f4
  return $?
}

#######################################
# Create a user with disabled login.
# Do nothing if a user with matching information already exists.
# Arguments:
#   -u <value> - username
#   -U <value> - UID (optional)
#   -g <value> - primary group name (optional)
#   -G <value> - primary GID (optional)
#   -H         - do not create home directory (optional)
# Returns:
#   0 - if the user exists
#   non-zero - otherwise
#######################################
# TODO: check args
# TODO: create a workaround if adduser is not present.
bl::os::create_nologin_user() {
  # Parse and check arguments.
  local username
  local uid
  local groupname
  local gid
  local create_no_home="0"

  local OPTIND=1
  while getopts ":u:U:g:G:H" opt; do
    case "${opt}" in
      "u")
        username="${OPTARG}"
        ;;
      "U")
        uid="${OPTARG}"
        ;;
      "g")
        groupname="${OPTARG}"
        ;;
      "G")
        gid="${OPTARG}"
        ;;
      "H")
        create_no_home=1
        ;;
      \?)
        bl::log::error "Invalid option: -${OPTARG}"
        return 2
        ;;
      :)
        bl::log::error "Option -${OPTARG} requires an argument"
        return 2
        ;;
    esac
  done

  declare -r username
  declare -r uid
  declare -r groupname
  declare -r gid
  declare -r create_no_home

  if [[ -z "${username}" ]]; then
    bl::log::error "User name was not provided"
    return 2
  fi

  # Check if the user already exists.
  # If the user exists, check if all provided information matches his.
  if bl::os::user_exists "${username}"; then
    local -r existing_user_uid="$(bl::os::get_uid_by_username ${username})"
    local -r existing_user_gid="$(bl::os::get_primary_gid_by_username ${username})"
    local -r existing_user_groupname="$(bl::os::get_group_name_by_gid ${existing_user_gid})"
    if [[ ( -n "${uid}" && "${uid}" != "${existing_user_uid}" ) || \
          ( -n "${gid}" && "${gid}" != "${existing_user_gid}" ) || \
          ( -n "${groupname}" && "${groupname}" != "${existing_user_groupname}" ) ]]; then
      # There is a mismatch between provided info and existing user's.
      bl::log::error "User already exists with different uid/gid/groupname"
      return 1
    else
      # Info matches.
      return 0
    fi
  fi

  # Do the job.
  local adduser_args+="--gecos \"\" --disabled-password --disabled-login --shell /usr/sbin/nologin"
  if [[ "${create_no_home}" = "1" ]]; then
    adduser_args+=" --no-create-home"
  fi
  if [[ -n "${uid}" ]]; then
    adduser_args+=" --uid ${uid}"
  fi
  if [[ -n "${gid}" || -n "${groupname}" ]]; then
    if [[ -n "${gid}" ]]; then
      adduser_args+=" --ingroup ${gid}"
    elif [[ -n "groupname" ]]; then
      adduser_args+=" --ingroup ${groupname}"
    fi
  fi
  adduser_args+=" ${username}"

  bl::script::run_as_root "adduser" ${adduser_args}
}
