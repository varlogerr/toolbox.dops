# {{ SHLIB_KEEP = SHLIB_EXT_VARS }}
  # Robust new line. Reference: https://stackoverflow.com/a/64938613
  declare -g SHLIB_NL; SHLIB_NL="$(printf '\nX')"; SHLIB_NL="${SHLIB_NL%X}"
# {{/ SHLIB_KEEP }}
