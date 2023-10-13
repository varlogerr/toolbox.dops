shlib_meta_docblock_shlib_text_tpl() {
  shlib_meta_description "
    Compile template TEXT replacing '{{ KEY }}' with VALUE.
    Limitations:
      * multiline KEY and VALUE are not allowed
  "
  shlib_meta_usage "
    {{ CMD }} [-f] [-o] [-s] [--kv KEY=VALUE]... [--] TEXT...
    {{ CMD }} [OPTIONS] <<< TEXT
  "
  shlib_meta_opt \
    + FIRST :-f :--first --flag --description "
      Substitute KEY only when it's first non-space thing in the line
    " \
    + ONLY :-o :--only --flag --description "
      Only output affected lines
    " \
    + SINGLE :-s :--single --flag --description "
      Substitute only single (first met) occurrence
    " \
    + KV :--kv --multi --kv --hint KEY=VALUE --description "
      KEY ane VALUE for substitution. KEY can't contain '='.
      If VALUE is empty, {{ KEY }} gets removed with following spaces.
    "
  shlib_meta_arg \
    + TEXT --multi --stdin --description '
      Template text
    '
  shlib_meta_rc + 0 "OK" + 2 "Invalid input"
  # shellcheck disable=SC2016
  shlib_meta_demo '
    cat demo1.tpl - demo2.tpl <<< -----
    # ```OUTPUT
    # Hello, {{ NAME }}! How are you {{ NAME }}?
    # Just a line.
    # ---
    # {{ NAME }}, how are you? Nice weather, {{ NAME }}!
    # ```

    {{ CMD }} --kv NAME=Dude "$(cat demo1.tpl)" "$(cat demo2.tpl)"
    # ```OUTPUT
    # Hello, Dude! How are you Dude?
    # Just a line.
    # Dude, how are you? Nice weather, Dude!
    # ```

    cat demo1.tpl demo2.tpl | {{ CMD }} -f --kv NAME Dude
    # ```OUTPUT
    # Hello, {{ NAME }}! How are you {{ NAME }}?
    # Just a line.
    # Dude, how are you? Nice weather, {{ NAME }}!
    # ```

    cat demo1.tpl demo2.tpl | {{ CMD }} -o --kv=NAME=Dude
    # ```OUTPUT
    # Hello, Dude! How are you Dude?
    # Dude, how are you? Nice weather, Dude!
    # ```

    cat demo1.tpl demo2.tpl | {{ CMD }} -s --kv=NAME Dude
    # ```OUTPUT
    # Hello, Dude! How are you {{ NAME }}?
    # Just a line.
    # Dude, how are you? Nice weather, {{ NAME }}!
    # ```
  '
}

shlib_text_tpl() {
  # Autogen always unless meta-disabled log-toolname
  declare SHLIB_LOG_TOOLNAME="${SHLIB_LOG_TOOLNAME:-${FUNCNAME[0]}}"

  { # ARGS AUTOGEN
    declare STDIN             # Autogen always
    declare -a ERRBAG         # Autogen always
    # Save input
    declare -a INPUT=("${@}") # Autogen always

    declare _OPT_ENDOPTS=false  # Autogen always
    declare _OPT_HELP=false     # Autogen always
    declare OPT_FIRST=false     # Autogen by meta-opt `--flag`
    declare OPT_ONLY=false      # Autogen by meta-opt `--flag`
    declare OPT_SINGLE=false    # Autogen by meta-opt `--flag`
    declare -a OPT_KV           # Autogen by meta-opt `--multi`
    declare -a ARG_TEXT         # Autogen by meta-arg `--multi`

    # Autogen always (parse args)
    declare arg; while [[ $# -gt 0 ]]; do       # Autogen always
      ${_OPT_ENDOPTS} && arg='*' || arg="${1}"  # Autogen always

      case "${arg}" in
        # Autogen always unless meta-disabled endopts
        --            ) _OPT_ENDOPTS=true ;;
        # Autogen always unless meta-disabled help
        -\?|-h|--help )
          ! ${_OPT_HELP} && _OPT_HELP=true \
          || ERRBAG+=("Single occurrence allowed: '${1}'.")
          ;;
        # Autogen by meta-opt `--flag`
        -f|--first    )
          ! ${OPT_FIRST} && OPT_FIRST=true \
          || ERRBAG+=("Single occurrence allowed: '${1}'.")
          ;;
        -o|--only     )
          ! ${OPT_ONLY} && OPT_ONLY=true \
          || ERRBAG+=("Single occurrence allowed: '${1}'.")
          ;;
        -s|--single   )
          ! ${OPT_SINGLE} && OPT_SINGLE=true \
          || ERRBAG+=("Single occurrence allowed: '${1}'.")
          ;;
        # Autogen by meta-opt non-`--flag`
        --kv  )
          if [[ -z "${2+x}" ]]; then
            ERRBAG+=("Value required: '${1}'.")
          # Autogen by meta-opt `--kv`
          elif grep -q '=' <<< "${2}"; then
            OPT_KV+=("${2}")
          elif [[ -n "${3+x}" ]]; then
            OPT_KV+=("${2}=${3}"); shift
          else
            ERRBAG+=("Invalid key-value format: '${1} ${2}'.");
          fi

          shift
          ;;
        --kv=*  )
          declare kv="${1#*=}"

          if grep -q '=' <<< "${kv}"; then
            OPT_KV+=("${kv}")
          elif [[ -n "${2+x}" ]]; then
            OPT_KV+=("${kv}=${2}"); shift
          else
            ERRBAG+=("Invalid key-value format: '${1}'.");
          fi
          ;;
        -* ) ERRBAG+=("Unexpected option: '${1}'.") ;; # Autogen always unless meta-disabled inval-opt
        *  ) ARG_TEXT+=("${1}") ;; # Autogen by meta-arg `--multi`
      esac

      shift
    done

    # Autogen by meta-arg `--stdin`
    [[ -n "${ARG_TEXT+x}" ]] || {
      declare tmp; tmp="$(timeout 0.1 grep '')"
      declare RC=$?
      if [[ $RC -eq 0 ]]; then
        ARG_TEXT+=("${tmp}"); STDIN="${tmp}"
      # grep no-match RC is 1, timeout RC is 124 or greater
      elif [[ $RC -gt 1 ]]; then
        ERRBAG+=("TEXT is required.")
      fi
    }

    # Autogen always unless meta-disabled help
    ${_OPT_HELP} && {
      if [[ (${#INPUT[@]} -lt 2 && -z "${STDIN+x}") ]]; then
        # TODO: print help
        return 0
      fi

      ERRBAG+=("Help option is incompatible with other options and stdin.")
    }

    # Autogen always
    [[ ${#ERRBAG[@]} -gt 0 ]] && {
      log_err "${ERRBAG[@]}"
      return 2
    }
  } # ARGS AUTOGEN

  [[ ${#ARG_TEXT[@]} -lt 1 ]] && return

  # Unique keys and values, last win
  declare -A tmp
  declare -a KEYS VALS
  declare -i ix; for ((ix=${#OPT_KV[@]}-1; ix>=0; ix--)); do
    key="${OPT_KV[$ix]%%=*}"; val="${OPT_KV[$ix]#*=}"
    [[ -n "${tmp[$key]+x}" ]] && continue

    tmp["${key}"]=''
    KEYS+=("${key}"); VALS+=("${val}")
  done

  declare -a ESC_KEYS ESC_VALS
  declare -a filter1=(cat)
  [[ ${#KEYS[@]} -gt 0 ]] && {
    # Escape keys and values

    declare tmp; tmp="$(printf -- '%s\n' "${KEYS[@]}" | sed_escape)"
    mapfile -t ESC_KEYS <<< "${tmp}"
    tmp="$(printf -- '%s\n' "${VALS[@]}" | sed_escape -r)"
    mapfile -t ESC_VALS <<< "${tmp}"

    ${OPT_ONLY} && {
      # Print only affected lines filter

      declare keys_rex
      ${OPT_FIRST} && keys_rex="^\s*"
      keys_rex+='{{\s*\('"$(
        printf -- '%s\|' "${ESC_KEYS[@]}" | sed -e 's/\\|$//'
      )"'\)\s*}}'

      filter1=(grep -e "${keys_rex}")
    }
  }

  # Replacement filter
  declare -a filter2=(sed -e 's/^//')
  declare expr esc_val flags
  declare -i ix; for ix in "${!ESC_KEYS[@]}"; do
    ${OPT_SINGLE} || flags+=g
    ${OPT_FIRST} && expr="^\s*"

    expr+='{{\s*'"${ESC_KEYS[$ix]}"'\s*}}'

    esc_val="${ESC_VALS[$ix]}"
    [[ -n "${esc_val}" ]] && {
      filter2+=(-e "s/${expr}/${esc_val}/${flags}")
      continue
    }

    filter2+=(
      -e "s/\\s*${expr}\\s*\$//${flags}"
      -e "s/${expr}\\s*//${flags}"
    )
  done

  printf -- '%s\n' "${ARG_TEXT[@]}" | "${filter1[@]}" | "${filter2[@]}"
}

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

# shellcheck disable=SC2120
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

shlib_testblock_shlib_text_tpl() {
  :
  # TODO: shlib_text_tpl suite
}
