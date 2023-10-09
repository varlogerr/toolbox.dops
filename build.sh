#!/usr/bin/env bash

_build_conf() {
  declare -g SELF; SELF="${SELF_CQ1E70i3lV4RzcX-${0}}"
  declare -g SELF_DIR; SELF_DIR="$(dirname -- "${SELF}")"

  { ########## CONFBLOCK ##########
    declare -ag SOURCES=(
      "${SELF_DIR}/src/lib/basic.sh"
      # "${SELF_DIR}/src/lib/func.sh"
      "${SELF_DIR}/src/lib"
    )
    declare -ag TESTS=(
      "${SELF_DIR}/tests"
    )
    declare -Ag TARGET=(
      [tmp_dir]="${SELF_DIR}/tmp"
      [bin_file]="${SELF_DIR}/bin/shlib.sh"
    )
  } ########## CONFBLOCK ##########
} # _build_conf

# {{ SHLIB_QBSw4_MODULES_PLACEHOLDER }} {{/ SHLIB_QBSw4_MODULES_PLACEHOLDER }}

if ! (return 0 &>/dev/null) && [[ -n "${SELF_CQ1E70i3lV4RzcX}" ]] ; then (
  ###############
  #### BUILD ####
  ###############

  # Get configured SOURCES and TESTS array and TARGET map
  _build_conf

  declare TARGET_MERGE="${TARGET[tmp_dir]}/build.merge.sh"
  (set -x
    mkdir -p "${TARGET[tmp_dir]}" 2>/dev/null \
    || echo "Can't create ${TARGET[tmp_dir]}" >&2
  ) && (
    set -o pipefail
    source_build_merge "${SOURCES[@]}" \
    | { set -x; tee -- "${TARGET_MERGE}" >/dev/null; }
  ) || exit $?

  declare TARGET_RAW="${TARGET[tmp_dir]}/build.raw.sh"
  (
    set -o pipefail
    source_build_raw "$(cat -- "${TARGET_MERGE}")" \
    | { set -x; tee -- "${TARGET_RAW}" >/dev/null; }
  ) || exit $?

  # TODO: run tests
  #
  # PLACEHOLDER FOR TESTS
  ${OPTS[test]} && exit

  if ! ${OPTS[noself]}; then (
    set -o pipefail
    _source_build_self "${TARGET[bin_file]}" \
      "${SELF}" "${TARGET_RAW}"
  ) || exit $?; fi
); exit $?; fi

###########################################################################
##############################               ##############################
############################## SERVICE BLOCK ##############################
##############################               ##############################
###########################################################################

if ! (return 0 &>/dev/null) && [[ "${1}" =~ ^(-\?|-h|--help)$ ]]; then (
  ##############
  #### HELP ####
  ##############

  _build_conf

  # shellcheck disable=SC2030
  SELF="$(basename -- "${SELF}")"
  {
    echo "
      Build '${TARGET[bin_file]}' script and update '${SELF}' with compiled functions
      (works only for shlib project). The sources for build are located in:
    "

    (if ! declare -p SOURCES 2>/dev/null | grep -q '^declare -a'; then
      echo "Script misconfiguration, SOURCES must be present and to be an array!"
    elif [[ ${#SOURCES[@]} -lt 1 ]]; then
      echo "SOURCES is not configured, see SETUP section of the help."
    else
      printf -- '* %s\n' "${SOURCES[@]}"
    fi) | sed 's/^/,  /'

    echo "
     ,
      Although the script is developed and used for shlib project, it's stand
      alone and can be used in other projects.
    "

    echo "
     ,
      USAGE:
     ,  ${SELF} OPTION
     ,  ${SELF} COMMAND
     ,
      OPTIONS:
     ,  -?, -h, --help  Print this help
     ,  --noself        Don't update ${SELF} (ignored in not shlib project)
     ,
      AVAILABLE COMMANDS:
     ,  test  - Only build until test stage
     ,
      SETUP:
     ,  Place '${SELF}' script to your project directory, configure
     ,  CONFBLOCK section under _build_conf function and \`${SELF}\`
    "
  } | grep -v '^ *$' | sed -e 's/^ \+//' -e 's/^,//'
); exit; fi

if ! (return 0 &>/dev/null); then (
  ##################################
  #### BUILD & EXEC TMP BUILDER ####
  ##################################

  declare SELF_SOURCE; SELF_SOURCE="$(cat -- "${BASH_SOURCE[0]}")"

  declare self_len; self_len="$(wc -l <<< "${SELF_SOURCE}")"

  # Detect modules template:
  declare MODULES_TPL tmp
  declare t; for t in \
    SHLIB_QBSw4_MODULES_TPL \
    SHLIB_QBSw4_OPTS_PARSE \
  ; do
    tmp="$(
      grep -x -m 1 -A "${self_len}" ' *# *{{ *'"${t}"' *}} *' \
        <<< "${SELF_SOURCE}" \
      | grep -x -m 1 -B "${self_len}" ' *# *{{\/ *'"${t}"' *}} *' \
      | tail -n +2 | head -n -1
    )"
    declare -i offset; offset="$(
      head -n 1 <<< "${tmp}" | sed 's/^\( *\).*/\1/' | wc -m
    )"
    # shellcheck disable=SC2001
    MODULES_TPL+="${MODULES_TPL+$'\n\n'}""$(
      sed -e 's/^\s\{0,'$((offset - 1))'\}//' <<< "${tmp}"
    )"
  done

  # Detect modules placeholder
  declare PLACEHOLDER_LINE; PLACEHOLDER_LINE="$(
    grep -n -x -m 1 ' *# *{{ *\(SHLIB_QBSw4_MODULES_PLACEHOLDER\) *}} *{{/ * \1 *}} *' \
      <<< "${SELF_SOURCE}" | cut -d: -f 1
  )"

  # Create and execute runner
  declare runner; runner="$(set -x; mktemp --suffix .shlib.build.sh)"
  (set -x; chmod +x "${runner}")
  (
    head -n $(( PLACEHOLDER_LINE - 1 )) <<< "${SELF_SOURCE}"
    echo "# {{ SHLIB_QBSw4_MODULES_PLACEHOLDER }}"
    cat <<< "${MODULES_TPL}"
    echo "# {{/ SHLIB_QBSw4_MODULES_PLACEHOLDER }}"
    tail -n +$(( PLACEHOLDER_LINE + 1 )) <<< "${SELF_SOURCE}"
  ) | (set -x; tee "${runner}") >/dev/null

  # Run tmp builder with passed rand var name
  SELF_CQ1E70i3lV4RzcX="${BASH_SOURCE[0]}" "${runner}" "${@}"
); exit; fi

_iife() {
  # This function is only here to keep the template,
  # don't touch this part of the code, but commit it
  # if it gets updated while developing shlib

  return

  # {{ SHLIB_QBSw4_OPTS_PARSE }}
    declare -A OPTS=(
      [test]=false
      [noself]=false
      [is_shlib]=false
    )

    _build_conf

    [[ -n "${TARGET[bin_file]}" && -f "${TARGET[bin_file]}" ]] \
    && {
      declare _binfile _projdir _marker
      _binfile="$(basename -- "${TARGET[bin_file]}")"
      _projdir="$(dirname -- "${TARGET[bin_file]}")/.."
      _marker="${_projdir}/src/.gitignore"
    } && [[ "${_binfile}" == shlib.sh ]] \
    && grep -qx '#\s*CQ1E70i3lV4RzcX' "${_marker}" &>/dev/null && {
      OPTS[is_shlib]=true
    }

    declare -a _errbag

    if [[ -n "${1+x}" ]]; then
      case "${1}" in
        --noself  ) OPTS[noself]=true ;;
        test      ) OPTS[test]=true ;;
        *         ) _errbag+=("Invalid argument: '${1}'") ;;
      esac
    fi

    [[ ${#_errbag[@]} -lt 1 ]] || {
      printf -- '%s\n' "${_errbag[@]}" >&2
      exit 2
    }

    # Force `--noself` if shlib markers are not in the project
    ${OPTS[is_shlib]} || OPTS[noself]=true
  # {{/ SHLIB_QBSw4_OPTS_PARSE }}

  # {{ SHLIB_QBSw4_MODULES_TPL }}
    # {{ SHLIB_KEEP = SHLIB_EXT_VARS }}
      # Robust new line
      # Reference: https://stackoverflow.com/a/64938613
      declare -g SHLIB_NL; SHLIB_NL="$(printf '\nX')"; SHLIB_NL="${SHLIB_NL%X}"
    # {{/ SHLIB_KEEP }}
    # {{ SHLIB_KEEP = SHLIB_EXT_VARS }}
      declare -g SHLIB_ASSOC_STORE_8jHoB
      # Can't contain ':'
      declare -g SHLIB_ASSOC_PREFIX_8jHoB='#&J)#cK'\''/g~~6[q!|)yQyY|F?*<d%Sa&0U'
    # {{/ SHLIB_KEEP }}
    # {{ SHLIB_KEEP = SHLIB_VARS }}
      declare CACHE_DIR_Fm4dq="/tmp/shlib.Fm4dq.$(id -u)"
      declare -A SHLIB_CACHE_Fm4dq
    # {{/ SHLIB_KEEP }}
    # {{ SHLIB_KEEP = SHLIB_VARS }}
      SHLIB_LOG_TOOLNAME="${SHLIB_LOG_TOOLNAME-shlib}"
    # {{/ SHLIB_KEEP }}
    # {{ SHLIB_EXT_CMDS }}
      _shlib_assoc_encode ()
      {
          declare is_key="${1}";
          shift;
          declare -a vals=("${@}");
          [[ $# -gt 0 ]] || vals=("$(timeout 0.2 cat)");
          declare -i ix;
          for ix in "${!vals[@]}";
          do
              ${is_key} && {
                  [[ ${ix} -gt 0 ]] && printf ':';
                  vals[$ix]="${SHLIB_ASSOC_PREFIX_8jHoB}:${vals[$ix]}"
              };
              base64 -w 0 <<< "${vals[$ix]}";
          done;
          echo
      }
      _shlib_assoc_esckey ()
      {
          sed 's/\//\\&/g'
      }
      shlib_assoc_get ()
      {
          [[ $# -gt 0 ]] || {
              echo "[${FUNCNAME[0]}:err] KEY is required." 1>&2;
              return 2
          };
          declare path;
          path="^$(
            _shlib_assoc_encode true "${@}" | _shlib_assoc_esckey
          ):";
          declare val;
          val="$(
            set -o pipefail
            grep -m1 "${path}" <<< "${SHLIB_ASSOC_STORE_8jHoB}" | sed 's/'"${path}"'//'
          )" || return 1;
          declare -a filter=(cat);
          grep -m1 -q ':' <<< "${val}" || filter=(base64 -d);
          "${filter[@]}" <<< "${val}"
      }
      shlib_assoc_is_assoc ()
      {
          declare val;
          val="$(timeout 0.2 cat)" || {
              echo "[${FUNCNAME[0]}:err] VALUE is required." 1>&2;
              return 2
          };
          [[ "$(
            (head -n 1 <<< "${val}"; printf ':')       | cut -d':' -f 1 | base64 -d 2>/dev/null
          )" == "${SHLIB_ASSOC_PREFIX_8jHoB}:"* ]]
      }
      shlib_assoc_keys ()
      {
          declare assoc="${SHLIB_ASSOC_STORE_8jHoB}";
          [[ "${1}" != '-' ]] || assoc="$(timeout 0.2 cat)" || {
              echo "[${FUNCNAME[0]}:err] VALUE is required." 1>&2;
              return 2
          };
          declare result;
          result="$(set -o pipefail
            # shellcheck disable=SC2001
            shlib_assoc_print - <<< "${assoc}" | rev | cut -d':' -f 2- | rev
          )" || return $?;
          sed 's/$/:/' <<< "${result}"
      }
      shlib_assoc_print ()
      {
          declare assoc="${SHLIB_ASSOC_STORE_8jHoB}";
          [[ "${1}" != '-' ]] || assoc="$(timeout 0.2 cat)" || {
              echo "[${FUNCNAME[0]}:err] VALUE is required." 1>&2;
              return 2
          };
          shlib_assoc_is_assoc <<< "${assoc}" || return 1;
          declare item tail;
          declare l;
          while read -r l; do
              item="$(cut -d':' -f1 <<< "${l}")";
              printf -- '%s:' "$(base64 -d <<< "${item}"         | sed 's/:/\\&/g' | cut -d':' -f2-)";
              tail="$(cut -d':' -f2- <<< "${l}")";
              "${FUNCNAME[0]}" - <<< "${tail}" || printf -- '%s\n' "${tail}";
          done <<< "${assoc}"
      }
      shlib_assoc_put ()
      {
          declare -a keys;
          keys=("${@}");
          [[ ${#keys[@]} -gt 0 ]] || {
              echo "[${FUNCNAME[0]}:err] KEY is required." 1>&2;
              return 2
          };
          declare val;
          val="$(set -o pipefail; timeout 0.2 cat | _shlib_assoc_encode false)" || {
              echo "[${FUNCNAME[0]}:err] VALUE is required." 1>&2;
              return 2
          };
          declare -a paths;
          declare -i ix;
          for ix in "${!keys[@]}";
          do
              [[ ${#paths[@]} -gt 0 ]] && paths[$((ix - 1))]+=":";
              paths[${ix}]="${paths[*]: -1}$(_shlib_assoc_encode true "${keys[${ix}]}")";
          done;
          SHLIB_ASSOC_STORE_8jHoB="$(grep -vxf <(
            printf -- '%s\n' "${paths[@]}" | _shlib_assoc_esckey       | sed -e 's/^/^/' -e 's/\([^:]\)$/\1.*/' -e 's/:$/:[^:]*/'
          ) <<< "${SHLIB_ASSOC_STORE_8jHoB}")";
          SHLIB_ASSOC_STORE_8jHoB+="${SHLIB_ASSOC_STORE_8jHoB:+${SHLIB_NL}}${paths[*]: -1}:${val}"
      }
      shlib_assoc_rm ()
      {
          [[ $# -gt 0 ]] || {
              echo "[${FUNCNAME[0]}:err] KEY is required." 1>&2;
              return 2
          };
          declare path;
          path="$(
            _shlib_assoc_encode true "${@}" | _shlib_assoc_esckey
          )";
          SHLIB_ASSOC_STORE_8jHoB="$(set -x; grep -v "^${path}:"       <<< "${SHLIB_ASSOC_STORE_8jHoB}")"
      }
    # {{/ SHLIB_EXT_CMDS }}
    _cache ()
    {
        _cache_file "${@}"
    }
    _cache_file ()
    {
        declare key="${1}";
        declare val=("${@:2}");
        key="$(sha1sum <<< "${key}" | cut -d' ' -f 1)";
        declare cache_file="${CACHE_DIR_Fm4dq}/${key}.cache";
        [[ ${#val[@]} -gt 0 ]] || {
            cat -- "${cache_file}" 2> /dev/null;
            return $?
        };
        ( ( declare cache_dir;
        cache_dir="$(realpath -- "${CACHE_DIR_Fm4dq}")";
        [[ "${cache_dir}" == '/tmp/'* ]] || exit;
        declare size;
        size="$(du "${CACHE_DIR_Fm4dq}" | grep -o -m 1 '^[0-9]\+')";
        [[ ${size} -gt 20480 ]] && rm -f "${CACHE_DIR_Fm4dq}"/*.cache ) & ) &> /dev/null;
        mkdir -p "${CACHE_DIR_Fm4dq}" 2> /dev/null;
        printf -- '%s\n' "${val[@]}" > "${cache_file}" 2> /dev/null;
        return 0
    }
    _cache_var ()
    {
        declare key="${1}";
        declare val=("${@:2}");
        key="$(sha1sum <<< "${key}" | cut -d' ' -f 1)";
        [[ ${#val[@]} -gt 0 ]] && {
            SHLIB_CACHE_Fm4dq["${key}"]="$(printf -- '%s\n' "${val[@]}")"
        } || [[ -n "${SHLIB_CACHE_Fm4dq[${key}]+x}" ]] && {
            printf -- '%s\n' "${SHLIB_CACHE_Fm4dq[${key}]}"
        } || return 1
    }
    _log_type ()
    {
        declare ARG_TYPE="${1}";
        declare -a ARG_MSG=("${@:2}");
        [[ ${#ARG_MSG[@]} -gt 0 ]] || ARG_MSG=("$(timeout 0.3 cat)") || {
            SHLIB_LOG_TOOLNAME="log_${ARG_TYPE}" log_err "MSG is required.";
            return 1
        };
        declare PREFIX="${SHLIB_LOG_TOOLNAME}";
        PREFIX+="${PREFIX:+:}${ARG_TYPE}";
        printf -- "%s\n" "${ARG_MSG[@]}" | text_offset -l 1 -t "[${PREFIX}] " 1>&2
    }
    _source_build_self ()
    {
        declare BIN_FILE="${1}";
        declare DEST="${2}";
        declare TARGET_RAW="${3}";
        [[ -n "${BIN_FILE}" && -f "${BIN_FILE}" && "$(basename -- "${BIN_FILE}")" == shlib.sh ]] || return 0;
        declare SHLIB_LOG_TOOLNAME=build.self;
        log_info "Updating ${DEST} modules template ...";
        declare tpl_tag=SHLIB_QBSw4_MODULES_TPL;
        declare DEST_CODE;
        DEST_CODE="$(cat -- "${DEST}")" || {
            log_err "Can't get ${DEST} code";
            exit 1
        };
        declare MODULES_CODE;
        MODULES_CODE="$(cat -- "${TARGET_RAW}")" || {
            log_err "Can't get ${TARGET_RAW} code";
            exit 1
        };
        declare positions;
        positions="$(tag_positions "${tpl_tag}" "${DEST_CODE}")" || {
            log_err "Can't get ${tpl_tag}";
            exit 1
        };
        [[ "$(wc -l <<< "${positions}")" -lt 2 ]] || {
            log_err "Only one ${tpl_tag} is allowed";
            exit 1
        };
        declare -A line=([start]="${positions%%:*}" [end]="${positions#*:}");
        [[ $(( line[end] - line[start])) -gt 1 ]] || {
            log_err "Minimum 1 line must present in ${tpl_tag}";
            exit 1
        };
        DEST_CODE="$(sed -e "$(( line[start] + 1 )),$(( line[end] - 1 ))d" <<< "${DEST_CODE}")";
        DEST_CODE+="${SHLIB_NL}#{{ ${tpl_tag} }}${SHLIB_NL}${MODULES_CODE}${SHLIB_NL}# {{/ ${tpl_tag} }}";
        ( set -o pipefail;
        tag_nodes_merge "${tpl_tag}" "${DEST_CODE}" | text_strip | ( set -x;
        tee "${SELF}" > /dev/null ) ) || {
            log_err "Can't update ${SELF}";
            exit 1
        };
        log_info "Updated  ${SELF} modules template" "SUCCESS"
    }
    _tag_get_meta_page ()
    {
        declare PREFIX="${1}" TEXT="${2}";
        declare cache_key="${FUNCNAME[0]}:${PREFIX}:${TEXT}";
        _cache "${cache_key}" || {
            declare escaped_prefix;
            escaped_prefix="$(sed_escape <<< "${PREFIX}")";
            declare name_expr='[[:alnum:]]([[:alnum:]_-]*[[:alnum:]])?';
            declare open_tag_expr='\{\{ *('"${name_expr}"')( *= *('${name_expr}'))? *\}\}';
            declare open_tag_line_expr='^([0-9]+): *'"${escaped_prefix}"' *'"${open_tag_expr}"'( *\{\{\/ *(\2) *\}\})? *$';
            TEXT="$(
          grep -n '' <<< "${TEXT}" | grep -E         -e "${open_tag_line_expr}"         -e '^([0-9]+): *'"${escaped_prefix}"' *\{\{\/ *'"${name_expr}"' *\}\} *$'
        )";
            declare -i len;
            len="$(wc -l <<< "${TEXT}")";
            declare -a keep;
            declare -a meta;
            declare -i offset=1;
            declare end_line;
            declare check_block;
            while check_block="$(
          set -o pipefail;
          grep -E -m 1 -n -A ${len} -e "${open_tag_line_expr}" <<< "${TEXT}"       | sed -E -e 's/^[0-9]+[:-]//'
        )"; do
                meta=($(head -n 1 <<< "${check_block}"         | sed -E -e 's/'"${open_tag_line_expr}"'/\1 \2=\5 \8/'));
                [[ ${#meta[@]} -lt 3 ]] || {
                    keep+=("${meta[0]}:${meta[0]}:${meta[1]}");
                    TEXT="$(tail -n +2 <<< "${TEXT}")";
                    continue
                };
                end_line="$(
            set -o pipefail
            grep -n -m 1 -E -e '^([0-9]+): *'"${escaped_prefix}"' *\{\{\/ *'"${meta[1]%%=*}"' *\}\} *$' <<< "${check_block}"
          )" && {
                    keep+=("${meta[0]}:$(cut -d ':' -f 2 <<< "${end_line}"):${meta[1]}");
                    TEXT="$(tail -n +$(( $(cut -d ':' -f 1 <<< "${end_line}") + 1 )) <<< "${TEXT}")";
                    continue
                };
                TEXT="$(tail -n +2 <<< "${TEXT}")";
            done;
            _cache "${cache_key}" "${keep[@]}";
            printf -- '%s\n' "${keep[@]}" | grep '.';
            return 0
        }
    }
    log_err ()
    {
        _log_type err "${@}"
    }
    log_fatal ()
    {
        _log_type fatal "${@}"
    }
    log_info ()
    {
        _log_type info "${@}"
    }
    log_warn ()
    {
        _log_type warn "${@}"
    }
    sed_escape ()
    {
        declare OPT_REPLACE=false;
        declare ARG_TEXT_CONTENT;
        declare arg;
        while [[ -n "${1+x}" ]]; do
            case "${1}" in
                -r | --replace)
                    OPT_REPLACE=true
                ;;
                *)
                    ARG_TEXT_CONTENT+="${ARG_TEXT_CONTENT+${SHLIB_NL}}${1}"
                ;;
            esac;
            shift;
        done;
        [[ -n "${ARG_TEXT_CONTENT+x}" ]] || ARG_TEXT_CONTENT="$(timeout 0.3 cat)";
        local rex='[]\/$*.^[]';
        ${OPT_REPLACE} && rex='[\/&]';
        sed -e 's/'"${rex}"'/\\&/g' <<< "${ARG_TEXT_CONTENT}"
    }
    source_build_merge ()
    {
        declare SHLIB_LOG_TOOLNAME=build.merge;
        declare IN_BUILD RESULT_CODE;
        declare -a MERGED FAILED;
        declare -a info_msg;
        [[ ${#} -gt 0 ]] && {
            info_msg=("Merging:" "$(text_offset -t '  * ' -l 1 "${@}")")
        } || {
            info_msg=("Merging ...")
        };
        log_info "${info_msg[@]}";
        function _iife ()
        {
            declare -a SOURCES=("${@}");
            declare external_tag='SHLIB_EXT_CMDS';
            declare keep_tag='SHLIB_KEEP';
            declare contents files_txt;
            declare -a files;
            declare contents_lines;
            declare source;
            for source in "${SOURCES[@]}";
            do
                [[ -n "${IN_BUILD+x}" ]] && grep -qFx "${source}" <<< "${IN_BUILD}" && {
                    log_info "Skip merging ${source}";
                    continue
                };
                IN_BUILD+="${IN_BUILD+${SHLIB_NL}}${source}";
                log_info "Merging ${source} ...";
                if contents="$(cat -- "${source}" 2>/dev/null)"; then
                    contents_lines="$(wc -l <<< "${contents}")";
                    contents="$(grep -e '[^\s]\+' -m 1 -A "${contents_lines}" <<< "${contents}")";
                    [[ -n "${contents}" ]] || continue;
                    declare KEEP_BLOCK;
                    KEEP_BLOCK="$(tag_nodes "${keep_tag}" "${contents}")" && {
                        contents="$(tag_nodes_rm "${keep_tag}" "${contents}")";
                        log_info "  ${keep_tag} tag extracted"
                    };
                    if tag_positions "${external_tag}" "${contents}" > /dev/null; then
                        contents="# {{ ${external_tag} }}${SHLIB_NL}$(
                tag_nodes_rm "${external_tag}" "${contents}"
              )${SHLIB_NL}# {{/ ${external_tag} }}";
                        log_info "  ${external_tag} tag wrapper applied";
                    fi;
                    [[ -n "${KEEP_BLOCK}" ]] && {
                        log_info "  ${keep_tag} elevated";
                        contents="$(printf -- '%s\n%s\n' "${KEEP_BLOCK}" "${contents}")"
                    };
                    RESULT_CODE+="${RESULT_CODE+${SHLIB_NL}${SHLIB_NL}}${contents}";
                    MERGED+=("${source}");
                    log_info "Merged  ${source}";
                    continue;
                fi;
                [[ -d "${source}" ]] || {
                    FAILED+=("${source}");
                    log_warn "'${source}' must be a file or a directory.";
                    continue
                };
                files_txt="$(find "${source}" -type f -name '*.sh' | sort -n)";
                [[ -n "${files_txt}" ]] || continue;
                mapfile -t files <<< "${files_txt}";
                "${FUNCNAME[0]}" "${files[@]}" > /dev/null;
                log_info "Merged  ${source}";
            done;
            external_body="$(tag_nodes_body "${external_tag}" "${RESULT_CODE}")";
            RESULT_CODE="$(tag_nodes_rm "${external_tag}" "${RESULT_CODE}")";
            RESULT_CODE="$(
          printf -- '# {{ %s }}\n%s\n# {{/ %s }}\n%s'         "${external_tag}" "$(
              text_offset "${external_body}"
            )" "${external_tag}" "${RESULT_CODE}"
        )";
            [[ -n "${RESULT_CODE}" ]] && printf -- '%s\n' "${RESULT_CODE}";
            return 0
        };
        _iife "${@}";
        unset _iife;
        declare -a info_msg;
        [[ ${#MERGED[@]} -gt 0 ]] && {
            log_info "Merged:" "$(text_offset -t '  * ' -l 1 "${MERGED[@]}")"
        };
        [[ ${#FAILED[@]} -gt 0 ]] && {
            log_err "Failed:" "$(text_offset -t '  * ' -l 1 "${FAILED[@]}")" "FAILURE";
            return 1
        };
        log_info "SUCCESS";
        return 0
    }
    source_build_raw ()
    {
        declare SOURCE="${1}";
        declare external_tag='SHLIB_EXT_CMDS';
        declare keep_tag='SHLIB_KEEP';
        declare SHLIB_LOG_TOOLNAME=build.raw;
        log_info "Building raw ...";
        log_info "${keep_tag} collecting ...";
        declare KEEP_BLOCK;
        KEEP_BLOCK="$(
        tag_nodes "${keep_tag}" "${SOURCE}"
      )" && {
            SOURCE="$(tag_nodes_rm "${keep_tag}" "${SOURCE}")";
            log_info "${keep_tag} collected"
        } || {
            log_info "${keep_tag} not detected"
        };
        log_info "${external_tag} collecting ...";
        declare EXTERNAL_BLOCK;
        EXTERNAL_BLOCK="$(
        set -o pipefail
        tag_nodes "${external_tag}" "${SOURCE}"     | tag_nodes_merge "${external_tag}"
      )" && {
            SOURCE="$(tag_nodes_rm "${external_tag}" "${SOURCE}")";
            log_info "${external_tag} collected"
        } || {
            log_info "${external_tag} not detected"
        };
        EXTERNAL_BLOCK="$(
        update="$(
          unset -f $(declare -F | rev | cut -d ' ' -f 1 | rev)
          . <(cat <<< "${EXTERNAL_BLOCK}")
          declare -f
        )"
        tag_nodes_update "${external_tag}" "${update}" "${EXTERNAL_BLOCK}"
      )";
        log_info "Getting func names ...";
        declare fnames_txt;
        fnames_txt="$(
        unset -f $(declare -F | rev | cut -d ' ' -f 1 | rev)
        . <(cat <<< "${SOURCE}")
        declare -F | rev | cut -d ' ' -f 1 | rev
      )" || {
            log_err "Can't get func names"
        };
        [[ -n "${fnames_txt}" ]] || {
            log_warn "No func names detected";
            return
        };
        declare -a fnames;
        mapfile -t fnames <<< "${fnames_txt}";
        log_info "Got func names";
        log_info "Getting func definitions ...";
        declare fdefs_txt;
        fdefs_txt="$(
        unset -f $(declare -F | rev | cut -d ' ' -f 1 | rev)
        . <(cat <<< "${SOURCE}")
        declare -f
      )" || {
            log_err "Can't get func definitions";
            return 1
        };
        declare -a fdefs;
        mapfile -t fdefs <<< "${fdefs_txt}";
        log_info "Got func definitions";
        ( echo "${KEEP_BLOCK}";
        echo "${EXTERNAL_BLOCK}";
        printf -- '%s\n' "${fdefs[@]}" ) | text_strip;
        log_info "SUCCESS"
    }
    tag_list_all ()
    {
        declare OPT_PREFIX='#';
        declare ARG_TEXT_CONTENT;
        declare arg;
        while [[ -n "${1+x}" ]]; do
            case "${1}" in
                --prefix)
                    shift;
                    OPT_PREFIX="${1}"
                ;;
                *)
                    ARG_TEXT_CONTENT+="${ARG_TEXT_CONTENT+${SHLIB_NL}}${1}"
                ;;
            esac;
            shift;
        done;
        [[ -n "${ARG_TEXT_CONTENT+x}" ]] || ARG_TEXT_CONTENT="$(timeout 0.3 cat)";
        _tag_get_meta_page "${OPT_PREFIX}" "${ARG_TEXT_CONTENT}" | grep ":${expr}" | cut -d: -f3- | sed 's/=$//' | uniq_ordered
    }
    tag_nodes ()
    {
        declare -a INPUT=("${@}");
        declare OPT_PREFIX='#';
        declare ARG_TAG;
        declare ARG_TEXT_CONTENT;
        declare arg;
        while [[ -n "${1+x}" ]]; do
            case "${1}" in
                --prefix)
                    shift;
                    OPT_PREFIX="${1}"
                ;;
                *)
                    [[ -n "${ARG_TAG+x}" ]] && {
                        ARG_TEXT_CONTENT+="${ARG_TEXT_CONTENT+${SHLIB_NL}}${1}"
                    } || {
                        ARG_TAG="${1}"
                    }
                ;;
            esac;
            shift;
        done;
        [[ -n "${ARG_TEXT_CONTENT+x}" ]] || ARG_TEXT_CONTENT="$(timeout 0.3 cat)";
        set -- "${@}" "${INPUT[@]}";
        declare cache_key;
        cache_key="${FUNCNAME[0]}:${OPT_PREFIX}:${ARG_TAG}:${ARG_TEXT_CONTENT}";
        _cache "${cache_key}" || {
            declare -a carry;
            declare -a positions;
            positions=($(tag_positions "${@}")) || return $?;
            declare -A line;
            declare p;
            for p in "${positions[@]}";
            do
                line=([start]="${p%%:*}" [end]="${p#*:}");
                carry+=("$(
            sed -n "${line[start]},${line[end]}p"           <<< "${ARG_TEXT_CONTENT}" | text_strip
          )");
            done;
            _cache "${cache_key}" "${carry[@]}" || return $?;
            printf -- '%s\n' "${carry[@]}"
        }
    }
    tag_nodes_body ()
    {
        declare -a INPUT=("${@}");
        declare OPT_PREFIX='#';
        declare ARG_TAG;
        declare ARG_TEXT_CONTENT;
        declare arg;
        while [[ -n "${1+x}" ]]; do
            case "${1}" in
                --prefix)
                    shift;
                    OPT_PREFIX="${1}"
                ;;
                *)
                    [[ -n "${ARG_TAG+x}" ]] && {
                        ARG_TEXT_CONTENT+="${ARG_TEXT_CONTENT+${SHLIB_NL}}${1}"
                    } || {
                        ARG_TAG="${1}"
                    }
                ;;
            esac;
            shift;
        done;
        [[ -n "${ARG_TEXT_CONTENT+x}" ]] || ARG_TEXT_CONTENT="$(timeout 0.3 cat)";
        set -- "${@}" "${INPUT[@]}";
        declare cache_key;
        cache_key="${FUNCNAME[0]}:${OPT_PREFIX}:${ARG_TAG}:${ARG_TEXT_CONTENT}";
        _cache "${cache_key}" || {
            declare -a carry;
            declare -a positions;
            positions=($(tag_positions "${@}")) || return $?;
            declare -A line;
            declare p;
            for p in "${positions[@]}";
            do
                line=([start]="$(( ${p%%:*} + 1 ))" [end]="$(( ${p#*:} - 1 ))");
                [[ ${line[end]} -lt ${line[start]} ]] && continue;
                carry+=("$(
            sed -n "${line[start]},${line[end]}p"           <<< "${ARG_TEXT_CONTENT}" | text_strip
          )");
            done;
            _cache "${cache_key}" "${carry[@]}" || return $?;
            printf -- '%s\n' "${carry[@]}"
        }
    }
    tag_nodes_merge ()
    {
        declare OPT_PREFIX='#';
        declare ARG_TAG;
        declare ARG_TEXT_CONTENT;
        declare arg;
        while [[ -n "${1+x}" ]]; do
            case "${1}" in
                --prefix)
                    shift;
                    OPT_PREFIX="${1}"
                ;;
                *)
                    [[ -n "${ARG_TAG+x}" ]] && {
                        ARG_TEXT_CONTENT+="${ARG_TEXT_CONTENT+${SHLIB_NL}}${1}"
                    } || {
                        ARG_TAG="${1}"
                    }
                ;;
            esac;
            shift;
        done;
        [[ -n "${ARG_TEXT_CONTENT+x}" ]] || ARG_TEXT_CONTENT="$(timeout 0.3 cat)";
        declare expr;
        expr="$(sed_escape "${ARG_TAG}")";
        [[ "${ARG_TAG}" == *=* ]] || expr+='=';
        declare keep;
        declare meta;
        if meta="$(
        set -o pipefail
        _tag_get_meta_page "${OPT_PREFIX}" "${ARG_TEXT_CONTENT}" | grep ":${expr}\$"
      )"; then
            declare -A line;
            declare tag;
            declare offset;
            declare -a keep;
            declare m;
            while read -r m; do
                line=([start]="$(cut -d: -f 1 <<< "${m}")" [end]="$(cut -d: -f 2 <<< "${m}")");
                tag="$(cut -d: -f 3 <<< "${m}")";
                [[ $(( line[end] - line[start] )) -gt 1 ]] && {
                    keep+=("$(
              sed -n -e "$(( line[start] + 1 )),$(( line[end] - 1 ))p"             <<< "${ARG_TEXT_CONTENT}" | text_strip | tac
            )")
                };
                declare offset;
                offset="$(
            sed "${line[start]}q;d" <<< "${ARG_TEXT_CONTENT}"         | sed 's/^\( *\).*/\1/' | wc -m
          )";
                (( offset-- ));
                ARG_TEXT_CONTENT="$(sed -e "${line[start]},${line[end]}d" <<< "${ARG_TEXT_CONTENT}")";
            done <<< "$(tac -- <<< "${meta}")";
            declare body_merged;
            declare b;
            for b in "${keep[@]}";
            do
                body_merged+="${body_merged+${SHLIB_NL}}${b}";
            done;
            [[ -n "${body_merged+x}" ]] && {
                body_merged="${SHLIB_NL}$(tac <<< "${body_merged}" | text_offset)${SHLIB_NL}${OPT_PREFIX} "
            };
            declare tag_name="${tag%%=*}";
            declare selector="${tag#*=}";
            declare tag_merged;
            tag_merged="$(
          printf -- '%s {{ %s%s }}%s{{/ %s }}'         "${OPT_PREFIX}" "${tag_name}" "${selector:+ = ${selector}}" "${body_merged}" "${tag_name}"       | text_offset -l "${offset}"
        )";
            ARG_TEXT_CONTENT="$(
          (
            head -n "$(( line[start] - 1 ))" <<< "${ARG_TEXT_CONTENT}"
            echo "${tag_merged}"
            tail -n +"${line[start]}" <<< "${ARG_TEXT_CONTENT}"
          )
        )";
        fi;
        printf -- '%s' "${ARG_TEXT_CONTENT}${ARG_TEXT_CONTENT:+${SHLIB_NL}}"
    }
    tag_nodes_rm ()
    {
        declare -a INPUT=("${@}");
        declare OPT_PREFIX='#';
        declare ARG_TAG;
        declare ARG_TEXT_CONTENT;
        declare arg;
        while [[ -n "${1+x}" ]]; do
            case "${1}" in
                --prefix)
                    shift;
                    OPT_PREFIX="${1}"
                ;;
                *)
                    [[ -n "${ARG_TAG+x}" ]] && {
                        ARG_TEXT_CONTENT+="${ARG_TEXT_CONTENT+${SHLIB_NL}}${1}"
                    } || {
                        ARG_TAG="${1}"
                    }
                ;;
            esac;
            shift;
        done;
        [[ -n "${ARG_TEXT_CONTENT+x}" ]] || ARG_TEXT_CONTENT="$(timeout 0.3 cat)";
        set -- "${@}" "${INPUT[@]}";
        declare -a positions;
        positions=($(tag_positions "${@}"));
        declare -A line;
        declare -a filter=(sed -e '1 s/^//');
        declare p;
        for p in "${positions[@]}";
        do
            line=([start]="${p%%:*}" [end]="${p#*:}");
            filter+=(-e "${line[start]},${line[end]}d");
        done;
        "${filter[@]}" <<< "${ARG_TEXT_CONTENT}"
    }
    tag_nodes_update ()
    {
        declare -a INPUT=("${@}");
        declare OPT_PREFIX='#';
        declare ARG_TAG;
        declare ARG_UPDATE;
        declare ARG_TEXT_CONTENT;
        declare arg;
        while [[ -n "${1+x}" ]]; do
            case "${1}" in
                --prefix)
                    shift;
                    OPT_PREFIX="${1}"
                ;;
                *)
                    if [[ -z "${ARG_TAG+x}" ]]; then
                        ARG_TAG="${1}";
                    else
                        if [[ -z "${ARG_UPDATE+x}" ]]; then
                            ARG_UPDATE="${1}";
                        else
                            ARG_TEXT_CONTENT+="${ARG_TEXT_CONTENT+${SHLIB_NL}}${1}";
                        fi;
                    fi
                ;;
            esac;
            shift;
        done;
        [[ -n "${ARG_TEXT_CONTENT+x}" ]] || ARG_TEXT_CONTENT="$(timeout 0.3 cat)";
        set -- "${@}" "${INPUT[@]}";
        [[ -n "${ARG_UPDATE+x}" ]] || {
            return 2
        };
        declare expr;
        expr="$(sed_escape "${ARG_TAG}")";
        [[ "${ARG_TAG}" == *=* ]] && expr+='$' || expr+='=';
        declare meta;
        meta="$(
        set -o pipefail
        _tag_get_meta_page "${OPT_PREFIX}" "${ARG_TEXT_CONTENT}" | grep ":${expr}"
      )" && {
            declare -A line;
            declare -A node;
            declare tag;
            declare selector;
            declare -i offset;
            declare m;
            while read -r m; do
                line=([start]="$(cut -d: -f 1 <<< "${m}")" [end]="$(cut -d: -f 2 <<< "${m}")");
                tag="$(cut -d: -f 3 <<< "${m}")";
                selector="${tag#*=}";
                node[close]="${tag%%=*}";
                node[open]="${node[close]}${selector:+ = }${selector}";
                node[open]="${OPT_PREFIX} {{ ${node[open]} }}";
                node[close]="{{/ ${node[close]} }}";
                offset="$(
            sed "${line[start]}q;d" <<< "${ARG_TEXT_CONTENT}"         | sed 's/^\( *\).*/\1/' | wc -m
          )";
                (( offset-- ));
                [[ -n "${ARG_UPDATE}" ]] && {
                    node[full]="$(printf -- '%s\n%s\n%s\n' "${node[open]}"           "$(text_strip "${ARG_UPDATE}" | text_offset)"           "${OPT_PREFIX} ${node[close]}")"
                } || {
                    node[full]="$(printf -- '%s %s\n' "${node[open]}" "${node[close]}")"
                };
                ARG_TEXT_CONTENT="$(sed -e "${line[start]},${line[end]}d" <<< "${ARG_TEXT_CONTENT}")";
                ARG_TEXT_CONTENT="$(
            head -n "$(( line[start] - 1 ))" <<< "${ARG_TEXT_CONTENT}"
            echo "${node[full]}" | text_offset -l ${offset}
            tail -n +"${line[start]}" <<< "${ARG_TEXT_CONTENT}"
          )";
            done <<< "$(tac -- <<< "${meta}")"
        };
        printf -- '%s' "${ARG_TEXT_CONTENT}${ARG_TEXT_CONTENT+${SHLIB_NL}}"
    }
    tag_positions ()
    {
        declare OPT_PREFIX='#';
        declare ARG_TAG;
        declare ARG_TEXT_CONTENT;
        declare arg;
        while [[ -n "${1+x}" ]]; do
            case "${1}" in
                --prefix)
                    shift;
                    OPT_PREFIX="${1}"
                ;;
                *)
                    [[ -n "${ARG_TAG+x}" ]] && {
                        ARG_TEXT_CONTENT+="${ARG_TEXT_CONTENT+${SHLIB_NL}}${1}"
                    } || {
                        ARG_TAG="${1}"
                    }
                ;;
            esac;
            shift;
        done;
        [[ -n "${ARG_TEXT_CONTENT+x}" ]] || ARG_TEXT_CONTENT="$(timeout 0.3 cat)";
        declare expr;
        expr="$(sed_escape "${ARG_TAG}")";
        [[ "${ARG_TAG}" == *=* ]] && expr+='$' || expr+='=';
        ( set -o pipefail;
        _tag_get_meta_page "${OPT_PREFIX}" "${ARG_TEXT_CONTENT}" | grep ":${expr}" | cut -d: -f 1,2 )
    }
    text_offset ()
    {
        declare OPT_LEN=2;
        declare OPT_FIRST=false;
        declare OPT_TOKEN=' ';
        declare -a ARG_TEXT;
        declare arg;
        while [[ -n "${1+x}" ]]; do
            case "${1}" in
                -f | --first)
                    OPT_FIRST=true
                ;;
                -t | --token)
                    shift;
                    OPT_TOKEN="${1}"
                ;;
                -l | --len)
                    shift;
                    OPT_LEN="${1}"
                ;;
                *)
                    ARG_TEXT+=("${1}")
                ;;
            esac;
            shift;
        done;
        [[ ${#ARG_TEXT[@]} -gt 0 ]] || ARG_TEXT+=("$(timeout 0.3 cat)");
        declare token;
        token="$(
        # shellcheck disable=SC2001
        sed -e 's/[\\%]/&&/g' <<< "${OPT_TOKEN}"
      )";
        declare offset='';
        [[ ${OPT_LEN} -gt 0 ]] && offset="$(printf -- "${token}"'%.0s' $(seq 1 ${OPT_LEN}))";
        offset="$(sed_escape -r "${offset}")";
        declare expression='s/^/'"${offset}"'/';
        ${OPT_FIRST} && expression="1 ${expression}";
        ( for t in "${ARG_TEXT[@]}";
        do
            sed -e "${expression}" <<< "${t}";
        done )
    }
    text_strip ()
    {
        declare -a ARG_TEXT;
        declare arg;
        while [[ -n "${1+x}" ]]; do
            case "${1}" in
                *)
                    ARG_TEXT+=("${1}")
                ;;
            esac;
            shift;
        done;
        [[ ${#ARG_TEXT[@]} -gt 0 ]] || ARG_TEXT+=("$(timeout 0.3 cat)");
        declare t_lines;
        declare offset;
        declare t;
        for t in "${ARG_TEXT[@]}";
        do
            t_lines="$(wc -l <<< "${t}")";
            t="$(sed -e 's/\s*$//' <<< "${t}"       | grep -m 1 -A "${t_lines}" -e '.'       | tac | grep -m 1 -A "${t_lines}" -e '.' | tac)";
            offset="$(head -n 1 <<< "${t}" | sed -e 's/^\(\s*\).*/\1/' | wc -m)";
            sed -e 's/^\s\{0,'$((offset - 1))'\}//' <<< "${t}";
        done
    }
    uniq_ordered ()
    {
        declare -a txt=("${@}");
        [[ ${#txt[@]} -gt 0 ]] || txt=("$(cat)");
        declare -a revfilter=(cat);
        printf -- '%s\n' "${txt[@]}" | "${revfilter[@]}" | cat -n | sort -k2 -k1n | uniq -f1 | sort -nk1,1 | cut -f2- | "${revfilter[@]}"
    }
  # {{/ SHLIB_QBSw4_MODULES_TPL }}
}; _iife; unset _iife
