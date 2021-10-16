#!/bin/bash
. ./script.sh


#######################################
# Check if a user exists.
# Arguments:
#   Username/UID
# Returns:
#   0 if exists, non-zero otherwise.
#######################################
bl::os::user_exists() {
  local -r user="$1"

  getent passwd "${user}" &>/dev/null
  return $?
}

#######################################
# Check if a group exists.
# Arguments:
#   Groupname/GID
# Returns:
#   0 if exists, non-zero otherwise.
#######################################
bl::os::group_exists() {
  local -r group="$1"

  getent group "${group_name}" &>/dev/null
  return $?
}

#######################################
# Get username by uid.
# Arguments:
#   UID
# Outputs:
#   Writes username to stdout.
# Returns:
#   0 if user exists, non-zero otherwise.
#######################################
bl::os::get_username_by_uid() {
  local -r uid="$1"

  getent passwd "${uid}" | cut -d: -f1
  return $?
}

#######################################
# Get groupname by gid.
# Arguments:
#   GID
# Outputs:
#   Writes groupname to stdout.
# Returns:
#   0 if group exists, non-zero otherwise.
#######################################
bl::os::get_groupname_by_gid() {
  local -r gid="$1"

  getent group "${gid}" | cut -d: -f1
  return $?
}


# TODO: fix
# args: name, [uid, group, gid, nohome, service]
bashlib::os::create_user() (
  local OPTIND=1
  while getopts ":u:U:g:G:HS" opt; do
    case ${opt} in
      "u")
        local -r user_name="${OPTARG}"
        ;;
      "U")
        local -r uid="${OPTARG}"
        ;;
      "g")
        local -r group_name="${OPTARG}"
        ;;
      "G")
        local -r gid="${OPTARG}"
        ;;
      "H")
        local -r create_no_home=1
        ;;
      "S")
        local -r create_system_user=1
        ;;
      \?)
        bashlib::script::print_to_stderr "[!] os::create_user: Invalid option: -${OPTARG}"
        return 2
        ;;
      :)
        bashlib::script::print_to_stderr "[!] os::create_user: Option -${OPTARG} requires an argument"
        return 2
        ;;
    esac
  done

  if [[ ! -v user_name ]]; then
    bashlib::script::print_to_stderr "[!] os::create_user: User name was not provided"
  fi

  command="adduser"
  command+=" --gecos \"\""
  if [[ "${create_system_user}" = 1 ]]; then
    command+=" --system --disabled-password --disabled-login --shell /usr/sbin/nologin"
  fi
  if [[ "${create_no_home}" = 1 ]]; then
    command+=" --no-create-home"
  fi
  if [[ -v "uid" ]]; then
    command+=" --uid ${uid}"
  fi
  if [[ -v "gid" || -v "group_name" ]]; then
    if [[ -v "gid" ]]; then
      command+=" --ingroup ${gid}"
    elif [[ -v "group_name" ]]; then
      command+=" --ingroup ${group_name}"
    fi
  fi

  eval "${command}"
)
