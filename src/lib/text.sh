text_offset() {
  # TODO: * replace the simple form with autogened
  #       * revisit all function usages for `--`
  # {{ARG_PARSE=text_offset}}
    # TODO: must be 0+ digit
    declare OPT_LEN=2
    declare OPT_FIRST=false
    declare OPT_TOKEN=' '
    declare -a ARG_TEXT

    declare arg; while [[ -n "${1+x}" ]]; do
      case "${1}" in
        -f|--first  ) OPT_FIRST=true ;;
        -t|--token  ) shift; OPT_TOKEN="${1}" ;;
        -l|--len    ) shift; OPT_LEN="${1}" ;;
        *           ) ARG_TEXT+=("${1}") ;;
      esac

      shift
    done

    [[ ${#ARG_TEXT[@]} -gt 0 ]] || ARG_TEXT+=("$(timeout 0.3 cat)")
  # {{/ARG_PARSE}}

  declare token; token="$(
    # shellcheck disable=SC2001
    sed -e 's/[\\%]/&&/g' <<< "${OPT_TOKEN}"
  )"
  declare offset=''
  [[ ${OPT_LEN} -gt 0 ]] && offset="$(printf -- "${token}"'%.0s' $(seq 1 ${OPT_LEN}))"
  offset="$(sed_escape -r "${offset}")"

  declare expression='s/^/'"${offset}"'/'
  ${OPT_FIRST} && expression="1 ${expression}"
  (for t in "${ARG_TEXT[@]}"; do
    sed -e "${expression}" -e 's/^\s\+$//' <<< "${t}"
  done)
}

text_strip() {
  # TODO: * replace the simple form with autogened
  #       * revisit all function usages for `--`
  # {{ ARG_PARSE = text_strip }}
    declare -a ARG_TEXT

    declare arg; while [[ -n "${1+x}" ]]; do
      case "${1}" in
        * ) ARG_TEXT+=("${1}") ;;
      esac

      shift
    done

    [[ ${#ARG_TEXT[@]} -gt 0 ]] || ARG_TEXT+=("$(timeout 0.3 cat)")
  # {{/ ARG_PARSE }}

  declare t_lines
  declare offset
  declare t; for t in "${ARG_TEXT[@]}"; do
    t_lines="$(wc -l <<< "${t}")"
    # Remove blank lines from the beginning and the end.
    # For some reason for stdin input doesn't work if space-only
    # lines aren't trimmed to empty lines,
    t="$(sed -e 's/\s*$//' <<< "${t}" \
      | grep -m 1 -A "${t_lines}" -e '.' \
      | tac | grep -m 1 -A "${t_lines}" -e '.' | tac)"
    # Calculate first line offset
    offset="$(head -n 1 <<< "${t}" | sed -e 's/^\(\s*\).*/\1/' | wc -m)"
    # Trim offset
    sed -e 's/^\s\{0,'$((offset - 1))'\}//' -e 's/^\s\+$//' <<< "${t}"
  done
}
