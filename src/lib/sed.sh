sed_escape() {
  # TODO: * replace the simple form with autogened
  #       * revisit all function usages for `--`
  # {{ ARG_PARSE = sed_escape }}
    declare OPT_REPLACE=false
    declare ARG_TEXT_CONTENT

    declare arg; while [[ -n "${1+x}" ]]; do
      case "${1}" in
        -r|--replace  ) OPT_REPLACE=true ;;
        *             ) ARG_TEXT_CONTENT+="${ARG_TEXT_CONTENT+${SHLIB_NL}}${1}" ;;
      esac

      shift
    done

    [[ -n "${ARG_TEXT_CONTENT+x}" ]] || ARG_TEXT_CONTENT="$(timeout 0.3 cat)"
  # {{/ ARG_PARSE }}

  local rex='[]\/$*.^[]'
  ${OPT_REPLACE} && rex='[\/&]'

  sed -e 's/'"${rex}"'/\\&/g' <<< "${ARG_TEXT_CONTENT}"
}
