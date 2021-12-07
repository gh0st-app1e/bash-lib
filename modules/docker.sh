#!/usr/bin/env bash
#
# Docker helper functions.
#
# Dependencies:
#   - log
#


#######################################
# Resolve container's ID to its names.
# Arguments:
#   Container ID
# Outputs:
#   Names -> stdout
# Returns:
#   0
#######################################
bl::docker::container::id_to_names() {
  local -r id="$1"
  
  docker container ls --filter id="$id" --format '{{.Names}}'
}

#######################################
# List IDs of containers with a given label.
# Arguments:
#   Label
# Outputs:
#   Container IDs -> stdout
# Returns:
#   0
#######################################
bl::docker::container::get_by_label() {
  local -r label="$1"

  docker ps -q --filter label="${label}"
}

#######################################
# Resolve network's ID to its name.
# Arguments:
#   Container ID
# Outputs:
#   Names -> stdout
# Returns:
#   0
#######################################
bl::docker::network::id_to_name() {
  local -r id="$1"
  
  docker network ls --filter id="$id" --format '{{.Name}}'
}

#######################################
# Connect network(s) to container(s) by name or by labels.
# Does not work with Docker Swarm.
# Arguments:
#   --net-id=...          - Network ID
#   --net-name=...        - Network name (ignored if --net-id was provided)
#   --net-label=...       - Network label (ignored if other --net-* option was provided)
#   --container-id=...    - Container ID
#   --container-name=...  - Container name (ignored if --container-id was provided)
#   --container-label=... - Container label (ignored if other --container-* option was provided)
# Returns:
#   0 - on success
#   non-zero - otherwise
#######################################
# TODO: Add 1 argument to specify if the mode is docker/swarm
# and treat --target-name (ex. --container-name) accordingly
# to find services instead of containers and connect to them.
bl::docker::network::connect() {
  local network_id
  local network_name
  local network_label
  local container_id
  local container_name
  local container_label

  local OPTIND=1
  local optspec=":-:"
  while getopts "${optspec}" optchar; do
    case "${optchar}" in
      "-")
        case "${OPTARG}" in
          net-id=*)
            local value=${OPTARG#*=}
            network_id="${value}"
            ;;
          net-name=*)
            local value=${OPTARG#*=}
            network_name="${value}"
            ;;
          net-label=*)
            local value=${OPTARG#*=}
            network_label="${value}"
            ;;
          container-id=*)
            local value=${OPTARG#*=}
            container_id="${value}"
            ;;
          container-name=*)
            local value=${OPTARG#*=}
            container_name="${value}"
            ;;
          container-label=*)
            local value=${OPTARG#*=}
            container_label="${value}"
            ;;
          *)
            bl::log::error "Unknown option: --${OPTARG}"
            return 2
            ;;
        esac
        ;;
      \?)
        bl::log::error "Unknown option: -${OPTARG}"
        return 2
        ;;
      :)
        bl::log::error "Option -${OPTARG} requires an argument"
        return 2
        ;;
    esac
  done

  declare -r network_id
  declare -r network_name
  declare -r network_label
  declare -r container_id
  declare -r container_name
  declare -r container_label

  if [[ -z "${network_id}" && -z "${network_name}" && -z "${network_label}" ]]; then
    bl::log::error "Network spec (--net-id/--net-name/--net-label) was not provided"
    return 2
  fi
  if [[ -z "${container_id}" && -z "${container_name}" && -z "${container_label}" ]]; then
    bl::log::error "Container spec (--container-id/--container-name/--container-label) was not provided"
    return 2
  fi


  # Networks that will be connected to the containers.
  # Store only IDs for consistency between use cases.
  declare -a networks_to_connect
  if [[ -n "${network_id}" ]]; then
    networks_to_connect=("${network_id}")
  elif [[ -n "${network_name}" ]]; then
    readarray -t networks_to_connect < <(docker network ls -q --filter name="${network_name}")
  elif [[ -n "${network_label}" ]]; then
    bl::log::debug "Searching networks with label ${network_label}..."
    readarray -t networks_to_connect < <(docker network ls -q --filter label="${network_label}")
  fi
  declare -r networks_to_connect
  if [[ ${#networks_to_connect[@]} -eq 0 ]]; then
    bl::log::error "No suitable networks were found"
    return 1
  fi

  # Containers to connect the networks to.
  # Store only IDs for consistency between use cases.
  declare -a target_containers
  if [[ -n "${container_id}" ]]; then
    target_containers=("${container_id}")
  elif [[ -n "${container_name}" ]]; then
    readarray -t target_containers < <(docker container ls -q --filter "names=${container_name}")
  elif [[ -n "${container_label}" ]]; then
    bl::log::debug "Searching containers with label ${container_label}..."
    readarray -t target_containers < <(docker container ls -q --filter "label=${container_label}")
  fi
  declare -r target_containers
  if [[ ${#target_containers[@]} -eq 0 ]]; then
    bl::log::error "No target containers were found"
    return 1
  fi

  for network_to_connect in "${networks_to_connect[@]}"; do
    for target_container in "${target_containers[@]}"; do
      bl::log::debug "Connecting network \"$(bl::docker::network::id_to_name "${network_to_connect}")\" to \"$(bl::docker::container::id_to_names "${target_container}")\"..."
      docker network connect "${network_to_connect}" "${target_container}"
    done
  done
}
