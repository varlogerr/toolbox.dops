# {{ SHLIB_EXT_CMDS }} {{/ SHLIB_EXT_CMDS }}

shlib_meta_docblock_SHLIB_ASSOC_PUT() {
  shlib_meta_description "
    Put VALUE to associative store under PATH.
  "
  shlib_meta_usage  "{{ CMD }} PATH... <<< VALUE"
  shlib_meta_rc     0 "OK" -- 2 "Invalid input"
  shlib_meta_demo "
    # Put values
    {{ CMD }} foo <<< Bar
    {{ CMD }} info block1 <<< "Content 1"
    {{ CMD }} info block2 <<< "Content 2"
    {{ CMD }} info block3 sub-block <<< "Content 2 in sub-block"
  "
}
shlib_meta_docblock_SHLIB_ASSOC_GET() {
  shlib_meta_description "
    Get value stored under PATH in associative store.
  "
  shlib_meta_usage  "{{ CMD }} PATH..."
  shlib_meta_rc     0 "OK" -- 1 "KEY is not found" -- 2 "Invalid input"
  # shellcheck disable=SC2016
  shlib_meta_demo '
    {{ @SHLIB_ASSOC_PUT }}{{/ @SHLIB_ASSOC_PUT }}

    {{ CMD }} foobar || {
      echo "No foobar key"
    }                       # STDOUT: `No foobar key`

    {{ CMD }} foo           # STDOUT: `Bar`
    {{ CMD }} info block2   # STDOUT: `Content 2`

    {{ CMD }} info
    ```STDOUT:
      # 3 rows of:
      BASE64_ENCODED_REST_OF_THE_PATH:BASE64_ENCODED_VALUE
    ```
  '
}
shlib_meta_docblock_SHLIB_ASSOC_RM() {
  shlib_meta_description "
    Remove PATH from associative store.
  "
  shlib_meta_usage  "{{ CMD }} PATH..."
  shlib_meta_rc     0 "OK" -- 2 "Invalid input"
}
shlib_meta_docblock_SHLIB_ASSOC_IS_ASSOC() {
  shlib_meta_description "
    Check if VALUE is assoc.
  "
  shlib_meta_usage  "{{ CMD }} <<< VALUE"
  shlib_meta_rc     0 "It's assoc" -- 1 "It's not assoc" -- 2 "Invalid input"
  # shellcheck disable=SC2016
  shlib_meta_demo '
    {{ @SHLIB_ASSOC_PUT }}{{/ @SHLIB_ASSOC_PUT }}

    ({{ CMD@SHLIB_ASSOC_GET }} info | {{ CMD }}) && echo 'Yes'
    # STDOUT: `Yes`

    ({{ CMD@SHLIB_ASSOC_GET }} info block1 | {{ CMD }} || echo 'No'
    # STDOUT: `No`
  '
}
shlib_meta_docblock_SHLIB_ASSOC_KEYS() {
  shlib_meta_description "
    List PATHs from assoc VALUE. PATHs are returned in KEY[:SUBKEY]...
    format with ':' escaped in KEY / SUBKEY (':' -> '\:'). One PATH
    by line (unless PATH contains new line).
  "
  shlib_meta_usage  "
    # Check in the assoc store
    {{ CMD }}

    # Check in the passed VALUE
    {{ CMD }} - <<< VALUE
  "
  shlib_meta_rc     0 OK -- 1 "It's not assoc" -- 2 "Invalid input"
  # shellcheck disable=SC2016
  shlib_meta_demo '
    {{ @SHLIB_ASSOC_PUT }}{{/ @SHLIB_ASSOC_PUT }}

    {{ CMD }}
    ```STDOUT:
      foo:
      info:block1:
      info:block2:
      info:block3:sub-block:
    ```

    ({{ CMD@SHLIB_ASSOC_GET }} info block3 | {{ CMD }} -     # STDOUT: `sub-block:`
    ({{ CMD@SHLIB_ASSOC_GET }} foo | {{ CMD }} - || echo No  # STDOUT: `No`
  '
}
shlib_meta_docblock_SHLIB_ASSOC_PRINT() {
  shlib_meta_description "
    Same as shlib_assoc_keys, but with base64 encoded VALUEs.
    Format: KEY[:SUBKEY...]:BASE64_VALUE
  "
  shlib_meta_usage  "
    # Print decoded assoc store
    {{ CMD }}

    # Print decoded passed VALUE
    {{ CMD }} - <<< VALUE
  "
  shlib_meta_rc     0 OK -- 1 "It's not assoc" -- 2 "Invalid input"
}

# {{ SHLIB_KEEP = SHLIB_EXT_VARS }}
  declare -g SHLIB_ASSOC_STORE_8jHoB
  # Can't contain ':'
  declare -g SHLIB_ASSOC_PREFIX_8jHoB='#&J)#cK'\''/g~~6[q!|)yQyY|F?*<d%Sa&0U'
# {{/ SHLIB_KEEP }}

shlib_assoc_put() {
  declare -a ERRBAG

  declare -a keys; keys=("${@}"); [[ ${#keys[@]} -gt 0 ]] || {
    ERRBAG+=("[${FUNCNAME[0]}:err] KEY is required.")
  }
  declare val; val="$(set -o pipefail; timeout 0.2 cat | _shlib_assoc_encode false)" || {
    ERRBAG+=("[${FUNCNAME[0]}:err] VALUE is required.")
  }

  [[ ${#ERRBAG[@]} -lt 1 ]] || {
    printf -- '%s\n' "${ERRBAG[@]}" >&2
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
