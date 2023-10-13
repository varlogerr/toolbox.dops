# {{ SHLIB_KEEP = SHLIB_VARS }}
  # Cache directory for 'file' driver
  declare CACHE_DIR_Fm4dq; CACHE_DIR_Fm4dq="/tmp/shlib.Fm4dq.$(id -u)"
  # Cache variable for 'var' driver (currently unused)
  declare -A SHLIB_CACHE_Fm4dq
# {{/ SHLIB_KEEP }}

# USAGE:
#   # Set value
#   _cache KEY VAL
#
#   # Get value
#   _cache KEY
_cache() {
  _cache_file "${@}"
}

_cache_var() {
  declare key="${1}"
  declare val=("${@:2}")
  key="$(sha1sum <<< "${key}" | cut -d' ' -f 1)"

  [[ ${#val[@]} -gt 0 ]] && {
    SHLIB_CACHE_Fm4dq["${key}"]="$(printf -- '%s\n' "${val[@]}")"
  } || [[ -n "${SHLIB_CACHE_Fm4dq[${key}]+x}" ]] && {
    printf -- '%s\n' "${SHLIB_CACHE_Fm4dq[${key}]}"
  } || return 1
}

_cache_file() {
  declare key="${1}"
  declare val=("${@:2}")
  key="$(sha1sum <<< "${key}" | cut -d' ' -f 1)"

  declare cache_file="${CACHE_DIR_Fm4dq}/${key}.cache"

  [[ ${#val[@]} -gt 0 ]] || {
    cat -- "${cache_file}" 2>/dev/null
    return $?
  }

  (
    (
      declare cache_dir
      cache_dir="$(realpath -- "${CACHE_DIR_Fm4dq}")"

      # Ensure it's in the temp directory
      [[ "${cache_dir}" == '/tmp/'* ]] || exit

      declare size
      size="$(du "${CACHE_DIR_Fm4dq}" | grep -o -m 1 '^[0-9]\+')"

      [[ ${size} -gt 20480 ]] && rm -f "${CACHE_DIR_Fm4dq}"/*.cache
    ) &
  ) &>/dev/null

  mkdir -p "${CACHE_DIR_Fm4dq}" 2>/dev/null
  printf -- '%s\n' "${val[@]}" > "${cache_file}" 2>/dev/null

  return 0
}
