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
#   ?
#######################################
bl::docker::container::id_to_names() {
  local -r id="$1"
  
  docker container ls --filter id="${id}" --format '{{.Names}}'
}

#######################################
# List IDs of containers with a given label.
# Arguments:
#   Label
# Outputs:
#   Container IDs -> stdout
# Returns:
#   ?
#######################################
bl::docker::container::get_ids_by_label() {
  local -r label="$1"

  docker ps -q --filter label="${label}"
}

#######################################
# Resolve service's ID to its name.
# Arguments:
#   Service ID
# Outputs:
#   Name -> stdout
# Returns:
#   ?
#######################################
bl::docker::service::id_to_name() {
  local -r id="$1"
  
  docker service ls --filter id="${id}" --format '{{.Name}}'
}

#######################################
# Resolve network's ID to its name.
# Arguments:
#   Container ID
# Outputs:
#   Name -> stdout
# Returns:
#   0
#######################################
bl::docker::network::id_to_name() {
  local -r id="$1"
  
  docker network ls --filter id="$id" --format '{{.Name}}'
}

#######################################
# Connect/disconnect network(s) to/from target(s) by name or by labels.
# Target is a container or a service, depending on the mode of operation (compose/swarm).
# Arguments:
#   --mode=...          - Mode (compose/swarm)
#   --net-id=...        - Network ID
#   --net-name=...      - Network name (ignored if --net-id was provided)
#   --net-label=...     - Network label (ignored if other --net-* option was provided)
#   --target-id=...     - Target ID
#   --target-name=...   - Target name (ignored if --target-id was provided)
#   --target-label=...  - Target label (ignored if other --target-* option was provided)
# Returns:
#   0 - on success
#   non-zero - otherwise
#######################################
bl::docker::network() {
  local cmd="$1"
  shift

  local mode
  local network_id
  local network_name
  local network_label
  local target_id
  local target_name
  local target_label

  local OPTIND=1
  local optspec=":-:"
  while getopts "${optspec}" optchar; do
    case "${optchar}" in
      -)
        case "${OPTARG}" in
          mode=*)
            local value=${OPTARG#*=}
            mode="${value}"
            ;;
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
          target-id=*)
            local value=${OPTARG#*=}
            target_id="${value}"
            ;;
          target-name=*)
            local value=${OPTARG#*=}
            target_name="${value}"
            ;;
          target-label=*)
            local value=${OPTARG#*=}
            target_label="${value}"
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

  declare -r cmd
  declare -r mode
  declare -r network_id
  declare -r network_name
  declare -r network_label
  declare -r target_id
  declare -r target_name
  declare -r target_label

  case "${cmd}" in
    connect|disconnect)
      ;;
    *)
      bl::log::error "Bad command \"${cmd}\" - should be \"connect\" or \"disconnect\""
      ;;
  esac

  case "${mode}" in
    compose|swarm)
      ;;
    *)
      bl::log::error "Bad mode \"${mode}\" - should be \"compose\" or \"swarm\""
      ;;
  esac
  
  if [[ -z "${network_id}" && -z "${network_name}" && -z "${network_label}" ]]; then
    bl::log::error "Network spec (--net-id/--net-name/--net-label) was not provided"
    return 2
  fi
  
  if [[ -z "${target_id}" && -z "${target_name}" && -z "${target_label}" ]]; then
    bl::log::error "Container spec (--container-id/--container-name/--container-label) was not provided"
    return 2
  fi


  # Networks that will be connected to the targets.
  # Store only IDs for consistency between use cases.
  declare -a networks
  if [[ -n "${network_id}" ]]; then
    networks=("${network_id}")
  elif [[ -n "${network_name}" ]]; then
    readarray -t networks < <(docker network ls -q --filter name="${network_name}")
  elif [[ -n "${network_label}" ]]; then
    bl::log::debug "Searching networks with label ${network_label}..."
    readarray -t networks < <(docker network ls -q --filter label="${network_label}")
  fi
  declare -r networks
  if [[ ${#networks[@]} -eq 0 ]]; then
    bl::log::error "No suitable networks were found"
    return 1
  fi

  # Targets to connect the networks to.
  # Store only IDs for consistency between use cases.
  declare -a targets
  if [[ -n "${target_id}" ]]; then
      targets=("${target_id}")
  elif [[ "${mode}" == "compose" ]]; then
    if [[ -n "${target_name}" ]]; then
      readarray -t targets < <(docker container ls -q --filter "names=${target_name}")
    elif [[ -n "${target_label}" ]]; then
      bl::log::debug "Searching containers with label ${target_label}..."
      readarray -t targets < <(docker container ls -q --filter "label=${target_label}")
    fi
  elif [[ "${mode}" == "swarm" ]]; then
    if [[ -n "${target_name}" ]]; then
      readarray -t targets < <(docker service ls -q --filter "name=${target_name}")
    elif [[ -n "${target_label}" ]]; then
      bl::log::debug "Searching services with label ${target_label}..."
      readarray -t targets < <(docker service ls -q --filter "label=${target_label}")
    fi
  fi
  declare -r targets
  if [[ ${#targets[@]} -eq 0 ]]; then
    case "${cmd}" in
      "connect")
        bl::log::error "No targets were found"
        return 1
        ;;
      "disconnect")
        return 0
        ;;
    esac
  fi

  for network in "${networks[@]}"; do
    for target in "${targets[@]}"; do
      if [[ "${mode}" == "compose" ]]; then
        if [[ "${cmd}" == "connect" ]]; then
          bl::log::debug "Connecting network \"$(bl::docker::network::id_to_name "${network}")\" to container \"$(bl::docker::container::id_to_names "${target}")\"..."
          docker network connect "${network}" "${target}"
        elif [[ "${cmd}" == "disconnect" ]]; then
          bl::log::debug "Disconnecting network \"$(bl::docker::network::id_to_name "${network}")\" from container \"$(bl::docker::container::id_to_names "${target}")\"..."
          docker network disconnect "${network}" "${target}"
        fi
      elif [[ "${mode}" == "swarm" ]]; then
        if [[ "${cmd}" == "connect" ]]; then
          bl::log::debug "Connecting network \"$(bl::docker::network::id_to_name "${network}")\" to service \"$(bl::docker::service::id_to_name "${target}")\"..."
          docker service update --network-add "${network}" "${target}"
        elif [[ "${cmd}" == "disconnect" ]]; then
          bl::log::debug "Disconnecting network \"$(bl::docker::network::id_to_name "${network}")\" from service \"$(bl::docker::service::id_to_name "${target}")\"..."
          docker service update --network-rm "${network}" "${target}"
        fi
      fi
    done
  done
}
