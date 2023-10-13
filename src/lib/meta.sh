# {{ SHLIB_EXT_CMDS }} {{/ SHLIB_EXT_CMDS }}

# {{ SHLIB_KEEP = SHLIB_EXT_VARS }}
  # Meta assoc prefix-key
  declare -g SHLIB_META_PREFIX_8jHoB='#X;Oq/M$p8'
  # Function name currently being described
  declare -g SHLIB_META_FNAME
# {{/ SHLIB_KEEP }}

# {{ DRAFT }}
# * +
#   Options separator
# * NAME
#   Option name.
#   Internally in described function converted
#   'NAME' => 'OPT_NAME' i.e. prefixes with 'OPT_'.
# * :-o
#   Short option flag.
#   Can't contain '='.
# * :--option
#   Long option flag.
#   Can't contain '='.
# * --flag
#   Option is flag (without value).
#   Internally in described function value becomes bool with
#   'false` for default.
# * --multi
#   Multiple occurrence allowed.
#   In docs option is appended with '...', i.e. '[-o]...'.
#   Internally in described function represented as array.
#   Conflicts with `--flag`.
# * --kv
#   Means that expected value is KEY=VALUE, allowed formats:
#     * `--option kEY=VALUE`
#     * `--option kEY VALUE`
#     * `--option=kEY=VALUE`
#     * `--option=kEY VALUE`
#   Internally in described function value is always converted to
#   'KEY=VALUE', or in combination with `--multi` to `KEY=VALUE` array
#   'false` for default.
#   Conflicts with `--flag`.
# * --hint
#   Hint for value.
#   In docs in combination with first met flag converts to '-o HINT'.
#   Default hint is option name 'NAME'.
#   Conflicts with `--flag`.
# * --default
#   Default value.
#   In docs in combination with first met flag converts to "[-o 'DEFAULT']".
#   Internally in described function 'OPT_NAME' var defaults to 'DEFAULT'.
#   Conflicts with `--flag`, `--hint` and `--multi`.
# * --description
#   Option description.
# shlib_meta_opt
#   + NAME [:-o] [:--option] [--flag] [--multi] [--kv] [--hint HINT] \
#     [--default DEFAULT] [--description DESCRIPTION]
#
# * +
#   Arguments separator
# * NAME
#   Argument name.
#   Internally in described function converted
#   'NAME' => 'ARG_NAME' i.e. prefixes with 'ARG_'.
# * --multi
#   Multiple occurrence allowed.
#   In docs option is appended with '...', i.e. 'ARG...'.
#   Internally in described function represented as array.
#   Conflicts with previous `--multi` ARG for described function.
# * --optional
#   Optional argument.
#   In docs converts 'NAME' => '[NAME]'.
#   Conflicts with followed non-optional ARG.
# * --default
#   Argument's default value.
#   In docs converts 'NAME' => "NAME='DEFAULT'".
#   Implicitly makes the ARG optional.
# * --stdin
#   Read from stdin if not provided.
#   In docs creates new USAGE demo with NAME from stdin instead of ARG.
#   Conflicts with `--default` and `--optional`
# shlib_meta_arg \
#   + NAME [--multi] [--optional] [--default DEFAULT] [--stdin] \
#     [--description DESCRIPTION]
# {{/ DRAFT }}

# {{ SHLIB_KEEP = SHLIB_EXT_DOCBLOCK }}
  # For all shlib_meta_* functions that require FNAME it can be
  # passed via 'SHLIB_META_FNAME' env variable, I.e.
  # ```sh
  # SHLIB_META_FNAME=myfunc shlib_meta_* [ARGS]...
  # # instead of
  # shlib_meta_* myfunc [ARGS]...
  # ```
  #
  # * shlib_meta_description
  # * shlib_meta_usage
  # * shlib_meta_demo
  # * shlib_meta_more
  #   USAGE:
  #     # Set meta prop
  #     shlib_meta_* FNAME TEXT...
  #     shlib_meta_* FNAME <<< TEXT
  #
  #     # Get meta prop
  #     shlib_meta_* FNAME
  #
  # * shlib_meta_rc
  #   USAGE:
  #     # Set meta prop
  #     shlib_meta_rc FNAME RC DESCRIPTION... [-- RC DESCRIPTION]...
  #     shlib_meta_rc FNAME RC - <<< DESCRIPTION
  #
  #     # Get description for a specific RC
  #     shlib_meta_rc FNAME RC
  #     # Get description for all RCs
  #     shlib_meta_rc FNAME
# {{/ SHLIB_KEEP }}

shlib_meta_description()  { _shlib_meta "${@}"; }
shlib_meta_usage()        { _shlib_meta "${@}"; }
shlib_meta_demo()         { _shlib_meta "${@}"; }
shlib_meta_more()         { _shlib_meta "${@}"; }

shlib_meta_rc() {
  declare -a ERRBAG

  # Required for logger
  # shellcheck disable=SC2034
  declare SHLIB_LOG_TOOLNAME="${FUNCNAME[0]}"
  declare -a LOG_ERR_CMD=(log_err)
  declare -F "${LOG_ERR_CMD[@]}" &>/dev/null || LOG_ERR_CMD=(shlib_do log-err)

  declare ARG_FNAME
  declare ARG_RC
  declare -a ARG_DESCRIPTION
  declare -a ARG_DESCRIPTION_STDIN

  if [[ -n "${SHLIB_META_FNAME+x}" ]]; then
    ARG_FNAME="${SHLIB_META_FNAME}"
  elif [[ -n "${1+x}" ]]; then
    ARG_FNAME="${1}"; shift
  else
    ERRBAG+=("FNAME is required.")
  fi

  while [[ -n "${1+x}" ]]; do
    case "${1}" in
      -   ) [[ ${#ARG_DESCRIPTION[@]} -gt 0 ]] && ERRBAG+=(
              "Can't read DESCRIPTION from stdin, it's already provided from arguments."
            ) || ARG_DESCRIPTION_STDIN=("$(timeout 0.2 cat)") || ERRBAG+=(
              "DESCRIPTION is required from stdin."
            )
        ;;
      --  ) shift; break ;;
      *   ) if [[ -z "${ARG_RC+x}" ]]; then
              ARG_RC="${1}"
            elif [[ ${#ARG_DESCRIPTION_STDIN[@]} -lt 1 ]]; then
              ARG_DESCRIPTION+=("${1}")
            else
              ERRBAG+=("Can't read DESCRIPTION from argument, it's already provided from stdin.")
            fi
        ;;
    esac
    shift
  done

  [[ -z "${RC+x}" ]] || test "${ARG_RC}" -eq "${ARG_RC}" 2>/dev/null \
  && [[ "${ARG_RC}" -ge 0 && "${ARG_RC}" -le 255 ]] || ERRBAG+=(
    "RC must be an integer between 0 and 255"
  )

  ARG_DESCRIPTION+=("${ARG_DESCRIPTION_STDIN[@]}")

  [[ ${#ERRBAG[@]} -lt 1 ]] || {
    "${LOG_ERR_CMD[@]}" "${ERRBAG[@]}"
    return 2
  }

  declare -a path=("${SHLIB_META_PREFIX_8jHoB}" "${FUNCNAME[0]}" "${ARG_FNAME}")

  if [[ ${#ARG_DESCRIPTION[@]} -gt 0 ]]; then
    declare -a TEXT_STRIP_CMD=(text_strip)
    declare -F "${TEXT_STRIP_CMD[@]}" &>/dev/null || TEXT_STRIP_CMD=(shlib_do text-strip)

    shlib_assoc_put "${path[@]}" "${ARG_RC}" <<< "$(
      "${TEXT_STRIP_CMD[@]}" "${ARG_DESCRIPTION[@]}"
    )"
  elif [[ -n ${ARG_RC} ]]; then
    shlib_assoc_get "${path[@]}" "${ARG_RC}"
    return $?
  else
    shlib_assoc_get "${path[@]}"
    return $?
  fi

  [[ ${#} -gt 0 ]] || return 0

  # Validate rest input
  if [[ ${#} -lt 2 ]]; then
    ERRBAG+=("At least 2 arguments required after '--'")
  else
    declare rest; rest="$(printf -- '%s\n' "${@:1:2}")"

    [[ $(wc -l <<< "${rest}") -eq 2 ]] \
    && grep -qFx -- '--'  <<< "${rest}" && ERRBAG+=(
      "At least 2 arguments required between '--'"
    )
  fi

  [[ ${#ERRBAG[@]} -lt 1 ]] || {
    "${LOG_ERR_CMD[@]}" "${ERRBAG[@]}"
    return 2
  }

  # Continue setting props
  SHLIB_META_FNAME="${ARG_FNAME}" "${FUNCNAME[0]}" "${@}"
}

_shlib_meta() {
  declare upstream="${FUNCNAME[1]}"
  declare fname

  if [[ -n "${SHLIB_META_FNAME+x}" ]]; then
    fname="${SHLIB_META_FNAME}"
  elif [[ -n "${1+x}" ]]; then
    fname="${1}"; shift
  else
    echo "[${upstream}:err] FNAME is required." >&2
    return 2
  fi

  declare -a TEXT_STRIP_CMD=(text_strip)
  declare -F "${TEXT_STRIP_CMD[@]}" &>/dev/null || TEXT_STRIP_CMD=(shlib_do text_strip)

  declare -a token=("${SHLIB_META_PREFIX_8jHoB}" "${upstream}" "${fname}")

  [[ -n "${1+x}" ]] && {
    shlib_assoc_put "${token[@]}" <<< "$("${TEXT_STRIP_CMD[@]}" "${@}")"
    return
  }

  shlib_assoc_get "${token[@]}"
}
