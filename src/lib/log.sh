# {{ SHLIB_KEEP = SHLIB_VARS }}
  SHLIB_LOG_TOOLNAME="${SHLIB_LOG_TOOLNAME-shlib}"
# {{/ SHLIB_KEEP }}

log_info()  { _log_type info "${@}"; }
log_warn()  { _log_type warn "${@}"; }
log_err()   { _log_type err "${@}"; }
log_fatal() { _log_type fatal "${@}"; }

_log_type() {
  # TODO: * replace the simple form with autogened
  #       * revisit all function usages for `--`
  # {{ ARG_PARSE = tag_positions }}
    declare ARG_TYPE="${1}"
    declare -a ARG_MSG=("${@:2}")

    [[ ${#ARG_MSG[@]} -gt 0 ]] \
    || ARG_MSG=("$(timeout 0.3 cat)") \
    || {
      SHLIB_LOG_TOOLNAME="log_${ARG_TYPE}" \
        log_err "MSG is required."
      return 1
    }
  # {{/ARG_PARSE}}

  declare PREFIX="${SHLIB_LOG_TOOLNAME}"
  PREFIX+="${PREFIX:+:}${ARG_TYPE}"

  printf -- "%s\n" "${ARG_MSG[@]}" | text_offset -l 1 -t "[${PREFIX}] " >&2
}
