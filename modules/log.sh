#!/usr/bin/env bash
#
# Functions related to logging.
#
# Dependencies: none

export BASH_LIB_LOG_LEVEL=debug


#######################################
# Check whether a value is a valid log level.
# Arguments:
#   Value to check
# Returns:
#   0 if the value is a valid log level, non-zero otherwise.
#######################################
bl::log::check_log_level() {
  local -r level="${1}"
  if [[ "${level}" =~ ^debug$|^info$|^warn$|^error$|^fatal$ ]]; then
    return 0
  else
    return 1
  fi
}

#######################################
# Log the provided message. Log format:
# "[LEVEL] calling_function: message"
# If the name of the calling function is not available, it is omitted.
# Log records are color-formatted with ANSI color codes.
# Globals:
#   BASH_LIB_LOG_LEVEL: ro
# Arguments:
#   Log level (debug|info|warn|error|fatal)
#   Message
#   Descriptor to write the log record to; default=1
# Outputs:
#   Writes the log record to the provided descriptor.
# Returns:
#   0 if successful, non-zero otherwise.
#######################################
# TODO: check empty arguments, check fd
# TODO: set default fd for the log globally
bl::log::log() {
  # Color codes: reset;foreground;background.
  declare -A log_colours=( [debug]="0;90;49" [info]="0;39;49" [warn]="0;33;49" [error]="1;31;49" [fatal]="1;37;41" )
  declare -A log_levels=( [debug]=1 [info]=2 [warn]=3 [error]=4 [fatal]=5 )
  local -r reset_colour="\e[0m"

  ### Get and check args.
  local -r requested_level="${1}"
  local -r message="${2}"
  local -r outfd="${3:-1}"
  local -r current_level="${BASH_LIB_LOG_LEVEL}"
  # Maximum log level name length is 5, plus 2 brackets => max field width is 7.
  if ! bl::log::check_log_level "${current_level}"; then
    printf "%b%-7s %s: %s%b\n" "\e[${log_colours[error]}m" "[ERROR]" "${FUNCNAME[0]}" \
      "BASH_LIB_LOG_LEVEL(=${current_level}) is not a valid log level, should be debug|info|warn|error|fatal" \
      "${reset_colour}"
    return 2
  fi
  if ! bl::log::check_log_level "${requested_level}"; then
    printf "%b%-7s %s: %s%b\n" "\e[${log_colours[error]}m" "[ERROR]" "${FUNCNAME[0]}" \
      "Requested log level(=${requested_level}) is not a valid log level, should be debug|info|warn|error|fatal" \
      "${reset_colour}"
    return 2
  fi

  ### Do the job.
  local -r current_level_num="${log_levels[${BASH_LIB_LOG_LEVEL}]}"
  local -r requested_level_num="${log_levels[${requested_level}]}"

  if (( "${requested_level_num}" >= "${current_level_num}" )); then
    local -r set_colour="\e[${log_colours[${requested_level}]}m"

    # Include name of the caller function if possible.
    # If the caller function is one of facade functions, look one step further up in the stack.
    if [[ "${FUNCNAME[1]}" =~ ^bl::log:: ]]; then
      if bl::log::check_log_level "${FUNCNAME[1]#bl::log::}"; then
        local -r caller_function="${FUNCNAME[2]}"
      else
        local -r caller_function="${FUNCNAME[1]}"
      fi
    fi

    if [[ -n "${caller_function}" ]]; then
      printf "%b%-7s %s: %s%b\n" "${set_colour}" "[${requested_level^^}]" "${caller_function}" "${message}" "${reset_colour}" >&"${outfd}"
    else
      printf "%b%-7s %s%b\n" "${set_colour}" "[${requested_level^^}]" "${message}" "${reset_colour}" >&"${outfd}"
    fi
  fi
}

#######################################
# Log a debug message.
# For more info and functionality refer to bl::log::log().
# Arguments:
#   Message
# Outputs:
#   Writes the log record to stdout.
# Returns:
#   0 if successful, non-zero otherwise.
#######################################
bl::log::debug() {
  bl::log::log "debug" "$1"
}

#######################################
# Log an informational message.
# For more info and functionality refer to bl::log::log().
# Arguments:
#   Message
# Outputs:
#   Writes the log record to stdout.
# Returns:
#   0 if successful, non-zero otherwise.
#######################################
bl::log::info() {
  bl::log::log "info" "$1"
}

#######################################
# Log a warning message.
# For more info and functionality refer to bl::log::log().
# Arguments:
#   Message
# Outputs:
#   Writes the log record to stdout.
# Returns:
#   0 if successful, non-zero otherwise.
#######################################
bl::log::warn() {
  bl::log::log "warn" "$1"
}

#######################################
# Log an error message.
# For more info and functionality refer to bl::log::log().
# Arguments:
#   Message
# Outputs:
#   Writes the log record to stdout.
# Returns:
#   0 if successful, non-zero otherwise.
#######################################
bl::log::error() {
  bl::log::log "error" "$1"
}

#######################################
# Log a fatal error message.
# For more info and functionality refer to bl::log::log().
# Arguments:
#   Message
# Outputs:
#   Writes the log record to stdout.
# Returns:
#   0 if successful, non-zero otherwise.
#######################################
bl::log::fatal() {
  bl::log::log "fatal" "$1"
}
