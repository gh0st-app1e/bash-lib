#!/usr/bin/env bash
#
# Docker helper functions.
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
# Arguments:
#   --net-name=...        - Network name
#   --net-label=...       - Network label (ignored if --net-name was provided)
#   --container-name=...  - Container name
#   --container-label=... - Container label (ignored if --container-name was provided)
# Returns:
#   0
#######################################
bl::docker::network::connect() {
  local network
  local network_label
  local container
  local container_label

  local OPTIND=1
  local optspec=":-:"
  while getopts "${optspec}" optchar; do
    case "${optchar}" in
      "-")
        case "${OPTARG}" in
          net=*)
            local value=${OPTARG#*=}
            network="${value}"
            ;;
          net-label=*)
            local value=${OPTARG#*=}
            network_label="${value}"
            ;;
          container=*)
            local value=${OPTARG#*=}
            container="${value}"
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

  declare -r network
  declare -r network_label
  declare -r container
  declare -r container_label


  # Networks that will be connected to the containers.
  local networks_to_connect
  if [[ -n "${network}" ]]; then
    networks_to_connect=("${network}")
  elif [[ -n "${network_label}" ]]; then
    readarray -t networks_to_connect < <(docker network ls -q --filter "label=${network_label}")
  else
    bl::log::error "No networks were provided"
    return 2
  fi
  declare -r networks_to_connect

  # Containers to connect the networks to.
  local target_containers
  if [[ -n "${container}" ]]; then
    target_containers=("${container}")
  elif [[ -n "${container_label}" ]]; then
    readarray -t target_containers < <(docker container ls -q --filter "label=${container_label}")
  else
    bl::log::error "No containers were provided"
    return 2
  fi
  declare -r target_containers

  for network_to_connect in "${networks_to_connect[@]}"; do
    for target_container in ${target_containers}; do
      bl::log::debug "Connecting network \"$(bl::docker::network::id_to_name "${network_to_connect}")\" to \"$(bl::docker::container::id_to_names "${target_container}")\"..."
      docker network connect "${network_to_connect}" "${target_container}"
    done
  done
}
