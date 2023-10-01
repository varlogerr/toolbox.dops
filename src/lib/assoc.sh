# {{ SHLIB_EXT_CMDS }} {{/ SHLIB_EXT_CMDS }}

# {{ SHLIB_KEEP = SHLIB_EXT_VARS }}
  declare -g SHLIB_ASSOC_STORE_8jHoB
  # Can't contain ':'
  declare -g SHLIB_ASSOC_PREFIX_8jHoB='#&J)#cK'\''/g~~6[q!|)yQyY|F?*<d%Sa&0U'
# {{/ SHLIB_KEEP }}

# USAGE:
#   shlib_assoc_put KEY [SUBKEY]... <<< VALUE
# RC:
#   0 - all is fine
#   2 - invalid input
shlib_assoc_put() {
  declare -a keys; keys=("${@}"); [[ ${#keys[@]} -gt 0 ]] || {
    echo "[${FUNCNAME[0]}:err] KEY is required." >&2
    return 2
  }
  declare val; val="$(set -o pipefail; timeout 0.2 cat | _shlib_assoc_encode false)" || {
    echo "[${FUNCNAME[0]}:err] VALUE is required." >&2
    return 2
  }

  # Delete expressions
  declare -a paths
  declare -i ix; for ix in "${!keys[@]}"; do
    # Append ':' to all path items but the last one
    [[ ${#paths[@]} -gt 0 ]] && paths[$((ix - 1))]+=":"
    paths[${ix}]="${paths[*]: -1}$(_shlib_assoc_encode true "${keys[${ix}]}")"
  done

  # Delete current key path from the store
  SHLIB_ASSOC_STORE_8jHoB="$(grep -vxf <(
    printf -- '%s\n' "${paths[@]}" | _shlib_assoc_esckey \
    | sed -e 's/^/^/' -e 's/\([^:]\)$/\1.*/' -e 's/:$/:[^:]*/'
  ) <<< "${SHLIB_ASSOC_STORE_8jHoB}")"

  # Put key val to the store
  SHLIB_ASSOC_STORE_8jHoB+="${SHLIB_ASSOC_STORE_8jHoB:+${SHLIB_NL}}${paths[*]: -1}:${val}"
}

# USAGE:
#   shlib_assoc_get KEY [SUBKEY]...
# RC:
#   0 - all is fine
#   1 - KEY is not found
#   2 - invalid input
shlib_assoc_get() {
  [[ $# -gt 0 ]] || {
    echo "[${FUNCNAME[0]}:err] KEY is required." >&2
    return 2
  }

  declare path; path="^$(
    _shlib_assoc_encode true "${@}" | _shlib_assoc_esckey
  ):"

  declare val; val="$(
    set -o pipefail
    grep "${path}" <<< "${SHLIB_ASSOC_STORE_8jHoB}" | sed 's/'"${path}"'//'
  )" || return 1

  # Return unmodified if it's a struct or decoded
  declare -a filter=(cat)
  grep -m1 -q ':' <<< "${val}" || filter=(base64 -d)
  "${filter[@]}" <<< "${val}"
}

# USAGE:
#   shlib_assoc_rm KEY [SUBKEY]...
# RC:
#   0 - all is fine
#   2 - invalid input
shlib_assoc_rm() {
  [[ $# -gt 0 ]] || {
    echo "[${FUNCNAME[0]}:err] KEY is required." >&2
    return 2
  }

  declare path; path="$(
    _shlib_assoc_encode true "${@}" | _shlib_assoc_esckey
  )"

  # Delete current key path from the store
  SHLIB_ASSOC_STORE_8jHoB="$(set -x; grep -v "^${path}:" \
    <<< "${SHLIB_ASSOC_STORE_8jHoB}")"
}

# USAGE:
#   shlib_assoc_is_assoc <<< VALUE
# RC:
#   0 - it's an assoc
#   1 - it's not an assoc
#   2 - invalid input
shlib_assoc_is_assoc() {
  declare val; val="$(timeout 0.2 cat)" || {
    echo "[${FUNCNAME[0]}:err] VALUE is required." >&2
    return 2
  }

  [[ "$(
    (head -n 1 <<< "${val}"; printf ':') \
    | cut -d':' -f 1 | base64 -d 2>/dev/null
  )" == "${SHLIB_ASSOC_PREFIX_8jHoB}:"* ]]
}

# KEYs are returned in KEY[:SUBKEY...] format with
# ':' escaped in KEY/SUBKEY (':' -> '\:'). Single
# PATH by line (unless keys contain new lines)
#
# USAGE:
#   # Check in the assoc store
#   shlib_assoc_keys
#
#   # Check in the passed VALUE
#   shlib_assoc_keys - <<< VALUE
# RC:
#   0 - all is find
#   1 - it's not an assoc
#   2 - invalid input
shlib_assoc_keys() {
  declare assoc="${SHLIB_ASSOC_STORE_8jHoB}"
  [[ "${1}" != '-' ]] || assoc="$(timeout 0.2 cat)" || {
    echo "[${FUNCNAME[0]}:err] VALUE is required." >&2
    return 2
  }

  declare result; result="$(set -o pipefail
    # shellcheck disable=SC2001
    shlib_assoc_print - <<< "${assoc}" | rev | cut -d':' -f 2- | rev
  )" || return $?

  # shellcheck disable=SC2001
  sed 's/$/:/' <<< "${result}"
}

# Same as shlib_assoc_keys, but with base64 encoded
# VALUEs. format: KEY[:SUBKEY...]:BASE64_VALUE
#
# USAGE:
#   # Print decoded assoc store
#   shlib_assoc_print
#
#   # Print decoded passed VALUE
#   shlib_assoc_print - <<< VALUE
# RC:
#   0 - all is find
#   1 - it's not an assoc
#   2 - invalid input
shlib_assoc_print() {
  declare assoc="${SHLIB_ASSOC_STORE_8jHoB}"
  [[ "${1}" != '-' ]] || assoc="$(timeout 0.2 cat)" || {
    echo "[${FUNCNAME[0]}:err] VALUE is required." >&2
    return 2
  }

  shlib_assoc_is_assoc <<< "${assoc}" || return 1

  declare item tail
  declare l; while read -r l; do
    item="$(cut -d':' -f1 <<< "${l}")"
    printf -- '%s:' "$(base64 -d <<< "${item}" \
      | sed 's/:/\\&/g' | cut -d':' -f2-)"

    tail="$(cut -d':' -f2- <<< "${l}")"
    "${FUNCNAME[0]}" - <<< "${tail}" || printf -- '%s\n' "${tail}"
  done <<< "${assoc}"
}

# USAGE:
#   _shlib_assoc_esckey <<< VALUE
_shlib_assoc_esckey() { sed 's/\//\\&/g'; }

# USAGE:
#   _shlib_assoc_encode IS_KEY <<< VALUE
#   _shlib_assoc_encode IS_KEY VALUE...
_shlib_assoc_encode() {
  declare is_key="${1}"; shift
  declare -a vals=("${@}")
  [[ $# -gt 0 ]] || vals=("$(timeout 0.2 cat)")

  declare -i ix; for ix in "${!vals[@]}"; do
    ${is_key} && {
      [[ ${ix} -gt 0 ]] && printf ':'
      vals[$ix]="${SHLIB_ASSOC_PREFIX_8jHoB}:${vals[$ix]}"
    }
    base64 -w 0 <<< "${vals[$ix]}"
  done; echo
}
