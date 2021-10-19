#!/usr/bin/env bash


# Wrapping init in a function to avoid accidental messing with environment.
bl::init::main() {
  local -r bash_lib_modules="log file os script"

  # Relative.
  local -r bash_lib_dir="$(dirname "${BASH_SOURCE[0]}")"

  for module in ${bash_lib_modules}; do
    . "${bash_lib_dir}/modules/${module}.sh"
  done
}

bl::init::main
unset -f bl::init::main
