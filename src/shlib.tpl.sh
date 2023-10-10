#!/usr/bin/env bash

# {{ SHLIB_EXT_DOCBLOCK }} {{/ SHLIB_EXT_DOCBLOCK }}
# {{ SHLIB_EXT_VARS }} {{/ SHLIB_EXT_VARS }}
# {{ SHLIB_EXT_CMDS }} {{/ SHLIB_EXT_CMDS }}

shlib_do() (
  :
  # {{ SHLIB_VARS }} {{/ SHLIB_VARS }}
  # {{ SHLIB_CMDS }} {{/ SHLIB_CMDS }}
)

if ! (return 0 &>/dev/null); then
  # In bash `return` is only allowed in functions and sourced files,
  # so running as executable script.
  # Reference: https://stackoverflow.com/a/28776166

  SHLIB_LOG_TOOLNAME="$(basename -- "${BASH_SOURCE[@]}")" \
    shlib_do "${@}"

  exit "${?}"
fi
