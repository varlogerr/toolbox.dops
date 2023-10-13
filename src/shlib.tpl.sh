#!/usr/bin/env bash
# {{ SHLIB__SELFDOC }}
  # * {{ SHLIB__SELFDOC /}} will be removed
  # * {{ SHLIB_VARS /}} and {{ SHLIB_EXT_VARS /}} body will be filled by
  #   {{ SHLIB_KEEP = SHLIB_VARS|SHLIB_EXT_VARS /}} blocks bodies from src
  # * {{ SHLIB_EXT_CMDS /}} body will be filled by {{ SHLIB_EXT_CMDS /}}
  #   functions definitions from src
  # * {{ SHLIB_CMDS /}} body will be filled by other functions definitions from src
  # * {{ SHLIB_TEMPLATE /}} will be filled by {{ SHLIB_TEMPLATE = * /}} from src
  # * {{ SHLIB_DOCKBLOC_<FUNCNAME> /}} will
# {{/ SHLIB__SELFDOC }}

# {{ SHLIB_KEEP = SHLIB_EXT_VARS }} {{/ SHLIB_KEEP }}
# {{ SHLIB_EXT_CMDS }} {{/ SHLIB_EXT_CMDS }}

shlib_do() (
  :
  # {{ SHLIB_KEEP = SHLIB_VARS }} {{/ SHLIB_KEEP }}
  # {{ SHLIB_CMDS }} {{/ SHLIB_CMDS }}
  # {{ SHLIB_MAPPER }} {{/ SHLIB_MAPPER }}
)

if ! (return 0 &>/dev/null); then
  # In bash `return` is only allowed in functions and sourced files,
  # so running as executable script.
  # Reference: https://stackoverflow.com/a/28776166

  SHLIB_LOG_TOOLNAME="$(basename -- "${BASH_SOURCE[@]}")" \
    shlib_do "${@}"

  exit "${?}"

  #
  # Code here is prevented from evaluation
  #

  # {{ SHLIB_KEEP = SHLIB_TEMPLATE }} {{/ SHLIB_KEEP }}
fi
