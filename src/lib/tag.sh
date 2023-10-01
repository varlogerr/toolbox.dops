# Result format: 'START_LINE_NO:END_LINE_NO' (one by line)
# USAGE:
#   tag_positions [--prefix '#'] TAG[=SELECTOR] TEXT...
# RC:
#   0 - at least 1 tag found
#   1 - tag not found
tag_positions() {
  # TODO: * replace the simple form with autogened
  #       * revisit all function usages for `--`
  # {{ ARG_PARSE = tag_positions }}
    declare OPT_PREFIX='#'
    declare ARG_TAG
    declare ARG_TEXT_CONTENT

    declare arg; while [[ -n "${1+x}" ]]; do
      case "${1}" in
        --prefix    ) shift; OPT_PREFIX="${1}" ;;
        *           ) [[ -n "${ARG_TAG+x}" ]] && {
                        ARG_TEXT_CONTENT+="${ARG_TEXT_CONTENT+${SHLIB_NL}}${1}"
                      } || { ARG_TAG="${1}"; }
          ;;
      esac

      shift
    done

    [[ -n "${ARG_TEXT_CONTENT+x}" ]] || ARG_TEXT_CONTENT="$(timeout 0.3 cat)"
  # {{/ARG_PARSE}}

  declare expr; expr="$(sed_escape "${ARG_TAG}")"
  [[ "${ARG_TAG}" == *=* ]] && expr+='$' || expr+='='

  (
    set -o pipefail
    _tag_get_meta_page "${OPT_PREFIX}" "${ARG_TEXT_CONTENT}" \
      | grep ":${expr}" | cut -d: -f 1,2
  )
}

tag_list_all() {
  # TODO: * replace the simple form with autogened
  # {{ ARG_PARSE = tag_list_all }}
    declare OPT_PREFIX='#'
    declare ARG_TEXT_CONTENT

    declare arg; while [[ -n "${1+x}" ]]; do
      case "${1}" in
        --prefix    ) shift; OPT_PREFIX="${1}" ;;
        *           ) ARG_TEXT_CONTENT+="${ARG_TEXT_CONTENT+${SHLIB_NL}}${1}" ;;
      esac

      shift
    done

    [[ -n "${ARG_TEXT_CONTENT+x}" ]] || ARG_TEXT_CONTENT="$(timeout 0.3 cat)"
  # {{/ARG_PARSE}}

  _tag_get_meta_page "${OPT_PREFIX}" "${ARG_TEXT_CONTENT}" \
  | grep ":${expr}" | cut -d: -f3- | sed 's/=$//' | uniq_ordered
}

# RC:
#   0 - at least 1 tag found
#   1 - tag not found
tag_nodes() {
  # TODO: * replace the simple form with autogened
  #       * revisit all function usages for `--`
  #       * put args back to ${@}
  # {{ ARG_PARSE = tag_nodes }}
    declare -a INPUT=("${@}")
    declare OPT_PREFIX='#'
    declare ARG_TAG
    declare ARG_TEXT_CONTENT

    declare arg; while [[ -n "${1+x}" ]]; do
      case "${1}" in
        --prefix    ) shift; OPT_PREFIX="${1}" ;;
        *           ) [[ -n "${ARG_TAG+x}" ]] && {
                      ARG_TEXT_CONTENT+="${ARG_TEXT_CONTENT+${SHLIB_NL}}${1}"
                    } || { ARG_TAG="${1}"; }
          ;;
      esac

      shift
    done

    [[ -n "${ARG_TEXT_CONTENT+x}" ]] || ARG_TEXT_CONTENT="$(timeout 0.3 cat)"

    set -- "${@}" "${INPUT[@]}"
  # {{/ ARG_PARSE }}

  declare cache_key; cache_key="${FUNCNAME[0]}:${OPT_PREFIX}:${ARG_TAG}:${ARG_TEXT_CONTENT}"

  _cache "${cache_key}" || {
    declare -a carry
    declare -a positions
    positions=($(tag_positions "${@}" <<< "${ARG_TEXT_CONTENT}")) || return $?

    declare -A line
    declare p; for p in "${positions[@]}"; do
      line=([start]="${p%%:*}" [end]="${p#*:}")

      carry+=("$(
        sed -n "${line[start]},${line[end]}p" \
          <<< "${ARG_TEXT_CONTENT}" | text_strip
      )")
    done

    _cache "${cache_key}" "${carry[@]}" || return $?
    printf -- '%s\n' "${carry[@]}"
  }
}

# RC:
#   0 - at least 1 tag found
#   1 - tag not found
tag_nodes_body() {
  # TODO: * replace the simple form with autogened
  #       * revisit all function usages for `--`
  #       * put args back to ${@}
  # {{ ARG_PARSE = tag_nodes }}
    declare -a INPUT=("${@}")
    declare OPT_PREFIX='#'
    declare ARG_TAG
    declare ARG_TEXT_CONTENT

    declare arg; while [[ -n "${1+x}" ]]; do
      case "${1}" in
        --prefix    ) shift; OPT_PREFIX="${1}" ;;
        *           ) [[ -n "${ARG_TAG+x}" ]] && {
                      ARG_TEXT_CONTENT+="${ARG_TEXT_CONTENT+${SHLIB_NL}}${1}"
                    } || { ARG_TAG="${1}"; }
          ;;
      esac

      shift
    done

    [[ -n "${ARG_TEXT_CONTENT+x}" ]] || ARG_TEXT_CONTENT="$(timeout 0.3 cat)"

    set -- "${@}" "${INPUT[@]}"
  # {{/ ARG_PARSE }}

  declare cache_key; cache_key="${FUNCNAME[0]}:${OPT_PREFIX}:${ARG_TAG}:${ARG_TEXT_CONTENT}"

  _cache "${cache_key}" || {
    declare -a carry
    declare -a positions
    positions=($(tag_positions "${@}" <<< "${ARG_TEXT_CONTENT}")) || return $?

    declare -A line
    declare p; for p in "${positions[@]}"; do
      line=([start]="$(( ${p%%:*} + 1 ))" [end]="$(( ${p#*:} - 1 ))")

      [[ ${line[end]} -lt ${line[start]} ]] && continue
      carry+=("$(
        sed -n "${line[start]},${line[end]}p" \
          <<< "${ARG_TEXT_CONTENT}" | text_strip
      )")
    done

    _cache "${cache_key}" "${carry[@]}" || return $?
    printf -- '%s\n' "${carry[@]}"
  }
}

# Merges TAG=SELECTOR or TAG
# RC:
#   0 - at least 1 tag found
#   1 - tag not found
tag_nodes_merge() {
  # TODO: * replace the simple form with autogened
  #       * revisit all function usages for `--`
  # {{ ARG_PARSE = tag_positions }}
    declare OPT_PREFIX='#'
    declare ARG_TAG
    declare ARG_TEXT_CONTENT

    declare arg; while [[ -n "${1+x}" ]]; do
      case "${1}" in
        --prefix    ) shift; OPT_PREFIX="${1}" ;;
        *           ) [[ -n "${ARG_TAG+x}" ]] && {
                        ARG_TEXT_CONTENT+="${ARG_TEXT_CONTENT+${SHLIB_NL}}${1}"
                      } || { ARG_TAG="${1}"; }
          ;;
      esac

      shift
    done

    [[ -n "${ARG_TEXT_CONTENT+x}" ]] || ARG_TEXT_CONTENT="$(timeout 0.3 cat)"
  # {{/ARG_PARSE}}

  declare expr; expr="$(sed_escape "${ARG_TAG}")"
  [[ "${ARG_TAG}" == *=* ]] || expr+='='

  declare keep
  declare meta; if meta="$(
    set -o pipefail
    _tag_get_meta_page "${OPT_PREFIX}" "${ARG_TEXT_CONTENT}" | grep ":${expr}\$"
  )"; then
    declare -A line
    declare tag
    declare offset
    declare -a keep
    declare m; while read -r m; do
      line=([start]="$(cut -d: -f 1 <<< "${m}")" [end]="$(cut -d: -f 2 <<< "${m}")")
      tag="$(cut -d: -f 3 <<< "${m}")"

      [[ $(( line[end] - line[start] )) -gt 1 ]] && {
        keep+=("$(
          sed -n -e "$(( line[start] + 1 )),$(( line[end] - 1 ))p" \
            <<< "${ARG_TEXT_CONTENT}" | text_strip | tac
        )")
      }

      declare offset; offset="$(
        sed "${line[start]}q;d" <<< "${ARG_TEXT_CONTENT}" \
        | sed 's/^\( *\).*/\1/' | wc -m
      )"
      (( offset-- ))

      ARG_TEXT_CONTENT="$(sed -e "${line[start]},${line[end]}d" <<< "${ARG_TEXT_CONTENT}")"
    done <<< "$(tac -- <<< "${meta}")"

    declare body_merged
    declare b; for b in "${keep[@]}"; do
      body_merged+="${body_merged+${SHLIB_NL}}${b}"
    done

    [[ -n "${body_merged+x}" ]] && {
      body_merged="${SHLIB_NL}$(tac <<< "${body_merged}" | text_offset)${SHLIB_NL}${OPT_PREFIX} "
    }

    declare tag_name="${tag%%=*}"
    declare selector="${tag#*=}"
    declare tag_merged; tag_merged="$(
      printf -- '%s {{ %s%s }}%s{{/ %s }}' \
        "${OPT_PREFIX}" "${tag_name}" "${selector:+ = ${selector}}" "${body_merged}" "${tag_name}" \
      | text_offset -l "${offset}"
    )"

    ARG_TEXT_CONTENT="$(
      (
        head -n "$(( line[start] - 1 ))" <<< "${ARG_TEXT_CONTENT}"
        echo "${tag_merged}"
        tail -n +"${line[start]}" <<< "${ARG_TEXT_CONTENT}"
      )
    )"
  fi

  printf -- '%s' "${ARG_TEXT_CONTENT}${ARG_TEXT_CONTENT:+${SHLIB_NL}}"
}

# USAGE:
#   tag_nodes_update TAG UPDATE TEXT...
tag_nodes_update() {
  # TODO: * replace the simple form with autogened
  #       * revisit all function usages for `--`
  #       * put args back to ${@}
  # {{ ARG_PARSE = tag_nodes }}
    declare -a INPUT=("${@}")
    declare OPT_PREFIX='#'
    declare ARG_TAG
    declare ARG_UPDATE
    declare ARG_TEXT_CONTENT

    declare arg; while [[ -n "${1+x}" ]]; do
      case "${1}" in
        --prefix    ) shift; OPT_PREFIX="${1}" ;;
        *           ) if [[ -z "${ARG_TAG+x}" ]]; then
                        ARG_TAG="${1}"
                      elif [[ -z "${ARG_UPDATE+x}" ]]; then
                        ARG_UPDATE="${1}"
                      else
                        ARG_TEXT_CONTENT+="${ARG_TEXT_CONTENT+${SHLIB_NL}}${1}"
                      fi
          ;;
      esac

      shift
    done

    [[ -n "${ARG_TEXT_CONTENT+x}" ]] || ARG_TEXT_CONTENT="$(timeout 0.3 cat)"

    set -- "${@}" "${INPUT[@]}"
  # {{/ ARG_PARSE }}

  [[ -n "${ARG_UPDATE+x}" ]] || {
    # TODO: log error
    return 2
  }

  declare expr; expr="$(sed_escape "${ARG_TAG}")"
  [[ "${ARG_TAG}" == *=* ]] && expr+='$' || expr+='='

  declare meta; meta="$(
    set -o pipefail
    _tag_get_meta_page "${OPT_PREFIX}" "${ARG_TEXT_CONTENT}" | grep ":${expr}"
  )" && {
    declare -A line
    declare -A node
    declare tag
    declare selector
    declare -i offset
    declare m; while read -r m; do
      line=([start]="$(cut -d: -f 1 <<< "${m}")" [end]="$(cut -d: -f 2 <<< "${m}")")
      tag="$(cut -d: -f 3 <<< "${m}")"

      selector="${tag#*=}"
      node[close]="${tag%%=*}"
      node[open]="${node[close]}${selector:+ = }${selector}"

      node[open]="${OPT_PREFIX} {{ ${node[open]} }}"
      node[close]="{{/ ${node[close]} }}"

      offset="$(
        sed "${line[start]}q;d" <<< "${ARG_TEXT_CONTENT}" \
        | sed 's/^\( *\).*/\1/' | wc -m
      )"
      (( offset-- ))

      [[ -n "${ARG_UPDATE}" ]] && {
        node[full]="$(printf -- '%s\n%s\n%s\n' "${node[open]}" \
          "$(text_strip "${ARG_UPDATE}" | text_offset)" \
          "${OPT_PREFIX} ${node[close]}")"
      } || {
        node[full]="$(printf -- '%s %s\n' "${node[open]}" "${node[close]}")"
      }

      ARG_TEXT_CONTENT="$(sed -e "${line[start]},${line[end]}d" <<< "${ARG_TEXT_CONTENT}")"
      ARG_TEXT_CONTENT="$(
        head -n "$(( line[start] - 1 ))" <<< "${ARG_TEXT_CONTENT}"
        echo "${node[full]}" | text_offset -l ${offset}
        tail -n +"${line[start]}" <<< "${ARG_TEXT_CONTENT}"
      )"

    done <<< "$(tac -- <<< "${meta}")"
  }

  printf -- '%s' "${ARG_TEXT_CONTENT}${ARG_TEXT_CONTENT+${SHLIB_NL}}"
}

tag_nodes_rm() {
  # TODO: * replace the simple form with autogened
  #       * revisit all function usages for `--`
  #       * put args back to ${@}
  # {{ ARG_PARSE = tag_nodes }}
    declare -a INPUT=("${@}")
    declare OPT_PREFIX='#'
    declare ARG_TAG
    declare ARG_TEXT_CONTENT

    declare arg; while [[ -n "${1+x}" ]]; do
      case "${1}" in
        --prefix    ) shift; OPT_PREFIX="${1}" ;;
        *           ) [[ -n "${ARG_TAG+x}" ]] && {
                      ARG_TEXT_CONTENT+="${ARG_TEXT_CONTENT+${SHLIB_NL}}${1}"
                    } || { ARG_TAG="${1}"; }
          ;;
      esac

      shift
    done

    [[ -n "${ARG_TEXT_CONTENT+x}" ]] || ARG_TEXT_CONTENT="$(timeout 0.3 cat)"

    set -- "${@}" "${INPUT[@]}"
  # {{/ ARG_PARSE }}

  declare -a positions
  # shellcheck disable=SC2207
  positions=($(tag_positions "${@}" <<< "${ARG_TEXT_CONTENT}")) || return $?

  declare -A line
  declare -a filter=(sed -e '1 s/^//')
  declare p; for p in "${positions[@]}"; do
    line=([start]="${p%%:*}" [end]="${p#*:}")
    filter+=(-e "${line[start]},${line[end]}d")
  done

  "${filter[@]}" <<< "${ARG_TEXT_CONTENT}"
}

_tag_get_meta_page() {
  declare PREFIX="${1}" \
          TEXT="${2}"

  declare cache_key="${FUNCNAME[0]}:${PREFIX}:${TEXT}"

  _cache "${cache_key}" || {
    declare escaped_prefix; escaped_prefix="$(sed_escape <<< "${PREFIX}")"

    declare name_expr='[[:alnum:]]([[:alnum:]_-]*[[:alnum:]])?'
    declare open_tag_expr='\{\{ *('"${name_expr}"')( *= *('${name_expr}'))? *\}\}'
    declare open_tag_line_expr='^([0-9]+): *'"${escaped_prefix}"' *'"${open_tag_expr}"'( *\{\{\/ *(\2) *\}\})? *$'

    TEXT="$(
      grep -n '' <<< "${TEXT}" | grep -E \
        -e "${open_tag_line_expr}" \
        -e '^([0-9]+): *'"${escaped_prefix}"' *\{\{\/ *'"${name_expr}"' *\}\} *$'
    )"

    declare -i len; len="$(wc -l <<< "${TEXT}")"
    declare -a keep
    declare -a meta
    declare -i offset=1
    declare end_line
    declare check_block; while check_block="$(
      set -o pipefail;
      grep -E -m 1 -n -A ${len} -e "${open_tag_line_expr}" <<< "${TEXT}" \
      | sed -E -e 's/^[0-9]+[:-]//'
    )"; do
      # shellcheck disable=SC2207
      meta=($(head -n 1 <<< "${check_block}" \
        | sed -E -e 's/'"${open_tag_line_expr}"'/\1 \2=\5 \8/'))

      [[ ${#meta[@]} -lt 3 ]] || {
        # The string contains close tag
        keep+=("${meta[0]}:${meta[0]}:${meta[1]}")
        TEXT="$(tail -n +2 <<< "${TEXT}")"
        continue
      }

      end_line="$(
        set -o pipefail
        grep -n -m 1 -E -e '^([0-9]+): *'"${escaped_prefix}"' *\{\{\/ *'"${meta[1]%%=*}"' *\}\} *$' <<< "${check_block}"
      )" && {
        keep+=("${meta[0]}:$(cut -d ':' -f 2 <<< "${end_line}"):${meta[1]}")
        TEXT="$(tail -n +$(( $(cut -d ':' -f 1 <<< "${end_line}") + 1 )) <<< "${TEXT}")"
        continue
      }

      TEXT="$(tail -n +2 <<< "${TEXT}")"
    done

    _cache "${cache_key}" "${keep[@]}"
    printf -- '%s\n' "${keep[@]}" | grep '.'
    return 0
  }
}
