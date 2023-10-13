#!/usr/bin/env bash

# {{ SHLIB_KEEP = SHLIB_EXT_VARS }}
  # Robust new line. Reference: https://stackoverflow.com/a/64938613
  declare -g SHLIB_NL; SHLIB_NL="$(printf '\nX')"; SHLIB_NL="${SHLIB_NL%X}"
  # Assoc storage
  declare -g SHLIB_ASSOC_STORE_8jHoB
  # Can't contain ':'
  declare -g SHLIB_ASSOC_PREFIX_8jHoB='#&J)#cK'\''/g~~6[q!|)yQyY|F?*<d%Sa&0U'
  # Meta assoc prefix-key
  declare -g SHLIB_META_PREFIX_8jHoB='#X;Oq/M$p8'
  # Function name currently being described
  declare -g SHLIB_META_FNAME
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
      grep "${path}" <<< "${SHLIB_ASSOC_STORE_8jHoB}" | sed 's/'"${path}"'//'
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
      (head -n 1 <<< "${val}"; printf ':')     | cut -d':' -f 1 | base64 -d 2>/dev/null
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
          printf -- '%s:' "$(base64 -d <<< "${item}"       | sed 's/:/\\&/g' | cut -d':' -f2-)";
          tail="$(cut -d':' -f2- <<< "${l}")";
          "${FUNCNAME[0]}" - <<< "${tail}" || printf -- '%s\n' "${tail}";
      done <<< "${assoc}"
  }
  shlib_assoc_put ()
  {
      declare -a ERRBAG;
      declare -a keys;
      keys=("${@}");
      [[ ${#keys[@]} -gt 0 ]] || {
          ERRBAG+=("[${FUNCNAME[0]}:err] KEY is required.")
      };
      declare val;
      val="$(set -o pipefail; timeout 0.2 cat | _shlib_assoc_encode false)" || {
          ERRBAG+=("[${FUNCNAME[0]}:err] VALUE is required.")
      };
      [[ ${#ERRBAG[@]} -lt 1 ]] || {
          printf -- '%s\n' "${ERRBAG[@]}" 1>&2;
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
      printf -- '%s\n' "${paths[@]}" | _shlib_assoc_esckey     | sed -e 's/^/^/' -e 's/\([^:]\)$/\1.*/' -e 's/:$/:[^:]*/'
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
      SHLIB_ASSOC_STORE_8jHoB="$(set -x; grep -v "^${path}:"     <<< "${SHLIB_ASSOC_STORE_8jHoB}")"
  }
  shlib_meta_docblock_SHLIB_ASSOC_GET ()
  {
      shlib_meta_description "
      Get value stored under PATH in associative store.
    ";
      shlib_meta_usage "{{ CMD }} PATH...";
      shlib_meta_rc 0 "OK" -- 1 "KEY is not found" -- 2 "Invalid input";
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
  shlib_meta_docblock_SHLIB_ASSOC_IS_ASSOC ()
  {
      shlib_meta_description "
      Check if VALUE is assoc.
    ";
      shlib_meta_usage "{{ CMD }} <<< VALUE";
      shlib_meta_rc 0 "It's assoc" -- 1 "It's not assoc" -- 2 "Invalid input";
      shlib_meta_demo '
      {{ @SHLIB_ASSOC_PUT }}{{/ @SHLIB_ASSOC_PUT }}

      ({{ CMD@SHLIB_ASSOC_GET }} info | {{ CMD }}) && echo 'Yes'
      # STDOUT: `Yes`

      ({{ CMD@SHLIB_ASSOC_GET }} info block1 | {{ CMD }} || echo 'No'
      # STDOUT: `No`
    '
  }
  shlib_meta_docblock_SHLIB_ASSOC_KEYS ()
  {
      shlib_meta_description "
      List PATHs from assoc VALUE. PATHs are returned in KEY[:SUBKEY]...
      format with ':' escaped in KEY / SUBKEY (':' -> '\:'). One PATH
      by line (unless PATH contains new line).
    ";
      shlib_meta_usage "
      # Check in the assoc store
      {{ CMD }}

      # Check in the passed VALUE
      {{ CMD }} - <<< VALUE
    ";
      shlib_meta_rc 0 OK -- 1 "It's not assoc" -- 2 "Invalid input";
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
  shlib_meta_docblock_SHLIB_ASSOC_PRINT ()
  {
      shlib_meta_description "
      Same as shlib_assoc_keys, but with base64 encoded VALUEs.
      Format: KEY[:SUBKEY...]:BASE64_VALUE
    ";
      shlib_meta_usage "
      # Print decoded assoc store
      {{ CMD }}

      # Print decoded passed VALUE
      {{ CMD }} - <<< VALUE
    ";
      shlib_meta_rc 0 OK -- 1 "It's not assoc" -- 2 "Invalid input"
  }
  shlib_meta_docblock_SHLIB_ASSOC_PUT ()
  {
      shlib_meta_description "
      Put VALUE to associative store under PATH.
    ";
      shlib_meta_usage "{{ CMD }} PATH... <<< VALUE";
      shlib_meta_rc 0 "OK" -- 2 "Invalid input";
      shlib_meta_demo "
      # Put values
      {{ CMD }} foo <<< Bar
      {{ CMD }} info block1 <<< "Content 1"
      {{ CMD }} info block2 <<< "Content 2"
      {{ CMD }} info block3 sub-block <<< "Content 2 in sub-block"
    "
  }
  shlib_meta_docblock_SHLIB_ASSOC_RM ()
  {
      shlib_meta_description "
      Remove PATH from associative store.
    ";
      shlib_meta_usage "{{ CMD }} PATH...";
      shlib_meta_rc 0 "OK" -- 2 "Invalid input"
  }
  _shlib_meta ()
  {
      declare upstream="${FUNCNAME[1]}";
      declare fname;
      if [[ -n "${SHLIB_META_FNAME+x}" ]]; then
          fname="${SHLIB_META_FNAME}";
      else
          if [[ -n "${1+x}" ]]; then
              fname="${1}";
              shift;
          else
              echo "[${upstream}:err] FNAME is required." 1>&2;
              return 2;
          fi;
      fi;
      declare -a TEXT_STRIP_CMD=(text_strip);
      declare -F "${TEXT_STRIP_CMD[@]}" &> /dev/null || TEXT_STRIP_CMD=(shlib_do text_strip);
      declare -a token=("${SHLIB_META_PREFIX_8jHoB}" "${upstream}" "${fname}");
      [[ -n "${1+x}" ]] && {
          shlib_assoc_put "${token[@]}" <<< "$("${TEXT_STRIP_CMD[@]}" "${@}")";
          return
      };
      shlib_assoc_get "${token[@]}"
  }
  shlib_meta_demo ()
  {
      _shlib_meta "${@}"
  }
  shlib_meta_description ()
  {
      _shlib_meta "${@}"
  }
  shlib_meta_more ()
  {
      _shlib_meta "${@}"
  }
  shlib_meta_rc ()
  {
      declare -a ERRBAG;
      declare SHLIB_LOG_TOOLNAME="${FUNCNAME[0]}";
      declare -a LOG_ERR_CMD=(log_err);
      declare -F "${LOG_ERR_CMD[@]}" &> /dev/null || LOG_ERR_CMD=(shlib_do log-err);
      declare ARG_FNAME;
      declare ARG_RC;
      declare -a ARG_DESCRIPTION;
      declare -a ARG_DESCRIPTION_STDIN;
      if [[ -n "${SHLIB_META_FNAME+x}" ]]; then
          ARG_FNAME="${SHLIB_META_FNAME}";
      else
          if [[ -n "${1+x}" ]]; then
              ARG_FNAME="${1}";
              shift;
          else
              ERRBAG+=("FNAME is required.");
          fi;
      fi;
      while [[ -n "${1+x}" ]]; do
          case "${1}" in
              -)
                  [[ ${#ARG_DESCRIPTION[@]} -gt 0 ]] && ERRBAG+=("Can't read DESCRIPTION from stdin, it's already provided from arguments.") || ARG_DESCRIPTION_STDIN=("$(timeout 0.2 cat)") || ERRBAG+=("DESCRIPTION is required from stdin.")
              ;;
              --)
                  shift;
                  break
              ;;
              *)
                  if [[ -z "${ARG_RC+x}" ]]; then
                      ARG_RC="${1}";
                  else
                      if [[ ${#ARG_DESCRIPTION_STDIN[@]} -lt 1 ]]; then
                          ARG_DESCRIPTION+=("${1}");
                      else
                          ERRBAG+=("Can't read DESCRIPTION from argument, it's already provided from stdin.");
                      fi;
                  fi
              ;;
          esac;
          shift;
      done;
      [[ -z "${RC+x}" ]] || test "${ARG_RC}" -eq "${ARG_RC}" 2> /dev/null && [[ "${ARG_RC}" -ge 0 && "${ARG_RC}" -le 255 ]] || ERRBAG+=("RC must be an integer between 0 and 255");
      ARG_DESCRIPTION+=("${ARG_DESCRIPTION_STDIN[@]}");
      [[ ${#ERRBAG[@]} -lt 1 ]] || {
          "${LOG_ERR_CMD[@]}" "${ERRBAG[@]}";
          return 2
      };
      declare -a path=("${SHLIB_META_PREFIX_8jHoB}" "${FUNCNAME[0]}" "${ARG_FNAME}");
      if [[ ${#ARG_DESCRIPTION[@]} -gt 0 ]]; then
          declare -a TEXT_STRIP_CMD=(text_strip);
          declare -F "${TEXT_STRIP_CMD[@]}" &> /dev/null || TEXT_STRIP_CMD=(shlib_do text-strip);
          shlib_assoc_put "${path[@]}" "${ARG_RC}" <<< "$(
        "${TEXT_STRIP_CMD[@]}" "${ARG_DESCRIPTION[@]}"
      )";
      else
          if [[ -n ${ARG_RC} ]]; then
              shlib_assoc_get "${path[@]}" "${ARG_RC}";
              return $?;
          else
              shlib_assoc_get "${path[@]}";
              return $?;
          fi;
      fi;
      [[ ${#} -gt 0 ]] || return 0;
      if [[ ${#} -lt 2 ]]; then
          ERRBAG+=("At least 2 arguments required after '--'");
      else
          declare rest;
          rest="$(printf -- '%s\n' "${@:1:2}")";
          [[ $(wc -l <<< "${rest}") -eq 2 ]] && grep -qFx -- '--' <<< "${rest}" && ERRBAG+=("At least 2 arguments required between '--'");
      fi;
      [[ ${#ERRBAG[@]} -lt 1 ]] || {
          "${LOG_ERR_CMD[@]}" "${ERRBAG[@]}";
          return 2
      };
      SHLIB_META_FNAME="${ARG_FNAME}" "${FUNCNAME[0]}" "${@}"
  }
  shlib_meta_usage ()
  {
      _shlib_meta "${@}"
  }
# {{/ SHLIB_EXT_CMDS }}

shlib_do() (
  :
  # {{ SHLIB_KEEP = SHLIB_VARS }}
    # Cache directory for 'file' driver
    declare CACHE_DIR_Fm4dq; CACHE_DIR_Fm4dq="/tmp/shlib.Fm4dq.$(id -u)"
    # Cache variable for 'var' driver (currently unused)
    declare -A SHLIB_CACHE_Fm4dq
    # Logger tool name
    declare SHLIB_LOG_TOOLNAME
  # {{/ SHLIB_KEEP }}
  # {{ SHLIB_CMDS }}
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
    _src_build_file_fdefs ()
    {
        declare file="${1}";
        declare fnames="${2}";
        declare output;
        [[ -n "${fnames}" ]] || return 0;
        declare -i RC=0;
        declare fname;
        while read -r fname; do
            output+="${output+$SHLIB_NL}$(
          # Exit if stderr contains errors
          # shellcheck disable=SC1090
          . "${file}" 3>&1 1>&2 2>&3 | grep '.' >&2 && exit 1
          declare -f "${fname}"
        )" || {
                log_err "Error retrieving func definition: '${file}'";
                RC=1
            };
        done <<< "${fnames}";
        declare ext_tag=SHLIB_EXT_CMDS;
        declare nodes;
        nodes="$(tag_nodes "${ext_tag}" < "${file}")" && {
            output="$(
          tag_nodes_merge "${ext_tag}" <<< "${nodes}"       | tag_nodes_update "${ext_tag}" "${output}"
        )"
        };
        printf -- '%s' "${output}${output:+$SHLIB_NL}";
        return ${RC}
    }
    _src_build_file_fnames ()
    {
        declare file="${1}";
        ( while read -r func; do
            [[ -n "${func}" ]] && unset -f "${func}";
        done < <(declare -F | rev | cut -d' ' -f1 | rev);
        . "${file}";
        declare -F | rev | cut -d' ' -f1 | rev ) || {
            log_err "Error sourcing: '${file}'";
            return 1
        }
    }
    _src_build_self ()
    {
        declare SHLIB_LOG_TOOLNAME=build.self;
        declare target_tag="${1}";
        declare source="${2}";
        declare noself="${3}";
        declare -i RC=0;
        ${noself} && {
            log_info "Skipping patching self.";
            return 0
        };
        log_info "Patching self ...";
        log_info "Patched self."
    }
    _src_build_text_tags ()
    {
        declare text;
        text="${1-$(cat)}";
        declare tags;
        tags="$(
        tag_list_all "${text}" | grep -v ^SHLIB_EXT_CMDS | grep '^SHLIB_'
      )" || return;
        [[ -n "${tags}" ]] || return 0;
        while read -r t; do
            tag_nodes "${t}" "${text}";
        done <<< "${tags}"
    }
    src_build_annotate ()
    {
        declare SHLIB_LOG_TOOLNAME=build.annotated;
        declare target="${1}";
        declare source="${2}";
        log_info "Building annotated ...";
        log_info "Writing: '${target}'";
        tee -- "${target}" < "${source}" > /dev/null || {
            log_err "Can't write: '${target}'";
            RC=1
        };
        log_info "Built annotated."
    }
    src_build_bin ()
    {
        declare SHLIB_LOG_TOOLNAME=build.bin;
        declare target="${1}";
        declare template="${2}";
        declare source="${3}";
        declare -i RC=0;
        log_info "Building bin ...";
        declare source_txt;
        source_txt="$(cat -- "$source")";
        declare template_txt;
        template_txt="$(tag_nodes_rm SHLIB__SELFDOC < "$template")";
        declare template_tags_txt;
        template_tags_txt="$(tag_list_all <<< "${template_txt}")";
        declare -a template_tags;
        [[ -n "${template_tags_txt}" ]] && mapfile -t template_tags <<< "${template_tags_txt}";
        declare -A block;
        declare tt;
        for tt in "${template_tags[@]}";
        do
            block[source]="$(
          tag_nodes "${tt}" <<< "${source_txt}"
        )" && block[source]="${SHLIB_NL}${block[source]}" || continue;
            log_info "Processing block: '${tt}'";
            source_txt="$(tag_nodes_rm "${tt}" <<< "${source_txt}")";
            block[tpl]="$(tag_nodes "${tt}" <<< "${template_txt}")";
            block[update]="$(tag_nodes_merge "${tt}" "${block[tpl]}${block[source]}" | tag_nodes_body "${tt}")";
            template_txt="$(tag_nodes_update "${tt}" "${block[update]}" <<< "${template_txt}")";
        done;
        declare -A block;
        declare tag=SHLIB_CMDS;
        if block[old]="$(tag_nodes "${tag}" <<< "${template_txt}")"; then
            log_info "Processing block: '${tag}'";
            block[update]="$(tag_nodes_update "${tag}" "${source_txt}" <<< "${block[old]}" | tag_nodes_body "${tag}")";
            template_txt="$(tag_nodes_update "${tag}" "${block[update]}" <<< "${template_txt}")";
        fi;
        declare -A block;
        declare tag=SHLIB_MAPPER;
        while block[old]="$(tag_nodes "${tag}" <<< "${template_txt}")"; do
            declare fnames;
            fnames="$(
          while read -r func; do
            unset -f  "${func}"
          done <<< "$(declare -F | rev | cut -d' ' -f1 | rev)"

          # shellcheck disable=SC1090
          . <(printf -- '%s\n' "${source_txt}")
          declare -F | rev | cut -d' ' -f1 | rev       | grep -v '^\(_\|shlib_meta_docblock_\)' | grep '.'
        )" || break;
            log_info "Processing block: '${tag}'";
            block[map]="declare -A ${tag}=(";
            while read -r fname; do
                block[map]+="${SHLIB_NL}  ['${fname//_/-}']='${fname}'";
            done <<< "${fnames}";
            block[map]+="${SHLIB_NL})";
            block[map]+="${SHLIB_NL}$(text_strip '
          [[ -n "${1+x}" ]] || {
            log_err "Command required."
            exit 2
          }
          [[ -n "${'"${tag}"'[${1}]+x}" ]] || {
            log_err "Invalid command: '\''${1}'\''"
            exit 2
          }

          local -r THE_CMD="${'"${tag}"'[${1}]}"; shift
          "${THE_CMD}" "${@}"; exit $?
        ')";
            template_txt="$(tag_nodes_update "${tag}" "${block[map]}" <<< "${template_txt}")";
            break;
        done;
        log_info "Writing: '${target}'";
        tee -- "${target}" <<< "${template_txt}" > /dev/null || {
            log_err "Can't write: '${target}'";
            RC=1
        };
        log_info "Built bin."
    }
    src_build_raw ()
    {
        declare SHLIB_LOG_TOOLNAME=build.raw;
        declare TARGET="${1}";
        declare -a SOURCES=("${@:2}");
        declare -i RC=0;
        declare PROCESSING RAW_TAGS RAW_DEFS;
        log_info "Generating raw source ...";
        function _iife_build_raw ()
        {
            declare -a SOURCES=("${@}");
            declare dir_sources_txt content;
            declare -a dir_sources;
            declare fnames fdefs tags;
            declare source;
            for source in "${SOURCES[@]}";
            do
                grep -qFx -- "${source}" <<< "${PROCESSING}" && {
                    log_info "Skipping:   '${source}'";
                    continue
                };
                PROCESSING+="${PROCESSING+$SHLIB_NL}${source}";
                log_info "Processing: '${source}' ...";
                if [[ -d "$(realpath -- "${source}" 2> /dev/null)" ]]; then
                    dir_sources_txt="$(find "${source}" -type f -name '*.sh' | sort -n)";
                    [[ -n "${dir_sources_txt}" ]] || {
                        log_warn "Empty dir:  '${source}'.";
                        continue
                    };
                    mapfile -t dir_sources <<< "${dir_sources_txt}";
                    "${FUNCNAME[0]}" "${dir_sources[@]}";
                    RC=$?;
                else
                    if content="$(cat -- "${source}" 2>/dev/null)"; then
                        tags="$(_src_build_text_tags <<< "${content}")";
                        [[ -n "${RAW_TAGS}" ]] && [[ -n "${tags}" ]] && RAW_TAGS+="${SHLIB_NL}";
                        RAW_TAGS+="${tags}";
                        fnames="$(_src_build_file_fnames "${source}")" || {
                            RC=${?};
                            continue
                        };
                        fdefs="$(_src_build_file_fdefs "${source}" "${fnames}")" || {
                            RC=${?};
                            continue
                        };
                        [[ -n "${RAW_DEFS}" ]] && [[ -n "${fdefs}" ]] && RAW_DEFS+="${SHLIB_NL}";
                        RAW_DEFS+="${fdefs}";
                    else
                        log_err "Can't read:  '${source}'.";
                        RC=1;
                        continue;
                    fi;
                fi;
                log_info "Processed:  '${source}'.";
            done;
            return ${RC}
        };
        _iife_build_raw "${SOURCES[@]}";
        RC=$?;
        unset _iife_build_raw;
        declare tags;
        tags="$(tag_list_all "${RAW_TAGS}")" && RAW_TAGS="$(while read -r t; do
        tag_nodes "${t}" "${RAW_TAGS}" | tag_nodes_merge "${t}"
      done <<< "${tags}")";
        log_info "Writing: '${TARGET}'";
        printf -- '%s%s' "${RAW_TAGS}" "${RAW_DEFS+$SHLIB_NL}${RAW_DEFS}" | tee -- "${TARGET}" > /dev/null || {
            log_err "Can't write: '${TARGET}'";
            RC=1
        };
        log_info "Generated raw source.";
        return ${RC}
    }
    src_build_test ()
    {
        declare SHLIB_LOG_TOOLNAME=build.test;
        declare test_file="${1}";
        declare source="${2}";
        declare -a tests=("${@:3}");
        log_info "Testing ...";
        log_info "Tested."
    }
    src_build_tmpdir ()
    {
        declare SHLIB_LOG_TOOLNAME=build.tmpdir;
        declare tmpdir="${1}";
        log_info "Creating tmp directory ...";
        log_info "Creating: '${tmpdir}' ...";
        mkdir -p -- "${tmpdir}" || {
            log_err "Can't create directory '${tmpdir}'.";
            return 1
        };
        log_info "Created tmp directory."
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
            positions=($(tag_positions "${@}" <<< "${ARG_TEXT_CONTENT}")) || return $?;
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
            positions=($(tag_positions "${@}" <<< "${ARG_TEXT_CONTENT}")) || return $?;
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
        positions=($(tag_positions "${@}" <<< "${ARG_TEXT_CONTENT}")) || return $?;
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
    shlib_meta_docblock_shlib_text_tpl ()
    {
        shlib_meta_description "
        Compile template TEXT replacing '{{ KEY }}' with VALUE.
        Limitations:
          * multiline KEY and VALUE are not allowed
      ";
        shlib_meta_usage "
        {{ CMD }} [-f] [-o] [-s] [--kv KEY=VALUE]... [--] TEXT...
        {{ CMD }} [OPTIONS] <<< TEXT
      ";
        shlib_meta_opt + FIRST :-f :--first --flag --description "
          Substitute KEY only when it's first non-space thing in the line
        " + ONLY :-o :--only --flag --description "
          Only output affected lines
        " + SINGLE :-s :--single --flag --description "
          Substitute only single (first met) occurrence
        " + KV :--kv --multi --kv --hint KEY=VALUE --description "
          KEY ane VALUE for substitution. KEY can't contain '='.
          If VALUE is empty, {{ KEY }} gets removed with following spaces.
        ";
        shlib_meta_arg + TEXT --multi --stdin --description '
          Template text
        ';
        shlib_meta_rc + 0 "OK" + 2 "Invalid input";
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
    shlib_testblock_shlib_text_tpl ()
    {
        :
    }
    shlib_text_tpl ()
    {
        declare SHLIB_LOG_TOOLNAME="${SHLIB_LOG_TOOLNAME:-${FUNCNAME[0]}}";
        {
            declare STDIN;
            declare -a ERRBAG;
            declare -a INPUT=("${@}");
            declare _OPT_ENDOPTS=false;
            declare _OPT_HELP=false;
            declare OPT_FIRST=false;
            declare OPT_ONLY=false;
            declare OPT_SINGLE=false;
            declare -a OPT_KV;
            declare -a ARG_TEXT;
            declare arg;
            while [[ $# -gt 0 ]]; do
                ${_OPT_ENDOPTS} && arg='*' || arg="${1}";
                case "${arg}" in
                    --)
                        _OPT_ENDOPTS=true
                    ;;
                    -\? | -h | --help)
                        ! ${_OPT_HELP} && _OPT_HELP=true || ERRBAG+=("Single occurrence allowed: '${1}'.")
                    ;;
                    -f | --first)
                        ! ${OPT_FIRST} && OPT_FIRST=true || ERRBAG+=("Single occurrence allowed: '${1}'.")
                    ;;
                    -o | --only)
                        ! ${OPT_ONLY} && OPT_ONLY=true || ERRBAG+=("Single occurrence allowed: '${1}'.")
                    ;;
                    -s | --single)
                        ! ${OPT_SINGLE} && OPT_SINGLE=true || ERRBAG+=("Single occurrence allowed: '${1}'.")
                    ;;
                    --kv)
                        if [[ -z "${2+x}" ]]; then
                            ERRBAG+=("Value required: '${1}'.");
                        else
                            if grep -q '=' <<< "${2}"; then
                                OPT_KV+=("${2}");
                            else
                                if [[ -n "${3+x}" ]]; then
                                    OPT_KV+=("${2}=${3}");
                                    shift;
                                else
                                    ERRBAG+=("Invalid key-value format: '${1} ${2}'.");
                                fi;
                            fi;
                        fi;
                        shift
                    ;;
                    --kv=*)
                        declare kv="${1#*=}";
                        if grep -q '=' <<< "${kv}"; then
                            OPT_KV+=("${kv}");
                        else
                            if [[ -n "${2+x}" ]]; then
                                OPT_KV+=("${kv}=${2}");
                                shift;
                            else
                                ERRBAG+=("Invalid key-value format: '${1}'.");
                            fi;
                        fi
                    ;;
                    -*)
                        ERRBAG+=("Unexpected option: '${1}'.")
                    ;;
                    *)
                        ARG_TEXT+=("${1}")
                    ;;
                esac;
                shift;
            done;
            [[ -n "${ARG_TEXT+x}" ]] || {
                declare tmp;
                tmp="$(timeout 0.1 grep '')";
                declare RC=$?;
                if [[ $RC -eq 0 ]]; then
                    ARG_TEXT+=("${tmp}");
                    STDIN="${tmp}";
                else
                    if [[ $RC -gt 1 ]]; then
                        ERRBAG+=("TEXT is required.");
                    fi;
                fi
            };
            ${_OPT_HELP} && {
                if [[ ( ${#INPUT[@]} -lt 2 && -z "${STDIN+x}" ) ]]; then
                    return 0;
                fi;
                ERRBAG+=("Help option is incompatible with other options and stdin.")
            };
            [[ ${#ERRBAG[@]} -gt 0 ]] && {
                log_err "${ERRBAG[@]}";
                return 2
            }
        };
        [[ ${#ARG_TEXT[@]} -lt 1 ]] && return;
        declare -A tmp;
        declare -a KEYS VALS;
        declare -i ix;
        for ((ix=${#OPT_KV[@]}-1; ix>=0; ix--))
        do
            key="${OPT_KV[$ix]%%=*}";
            val="${OPT_KV[$ix]#*=}";
            [[ -n "${tmp[$key]+x}" ]] && continue;
            tmp["${key}"]='';
            KEYS+=("${key}");
            VALS+=("${val}");
        done;
        declare -a ESC_KEYS ESC_VALS;
        declare -a filter1=(cat);
        [[ ${#KEYS[@]} -gt 0 ]] && {
            declare tmp;
            tmp="$(printf -- '%s\n' "${KEYS[@]}" | sed_escape)";
            mapfile -t ESC_KEYS <<< "${tmp}";
            tmp="$(printf -- '%s\n' "${VALS[@]}" | sed_escape -r)";
            mapfile -t ESC_VALS <<< "${tmp}";
            ${OPT_ONLY} && {
                declare keys_rex;
                ${OPT_FIRST} && keys_rex="^\s*";
                keys_rex+='{{\s*\('"$(
            printf -- '%s\|' "${ESC_KEYS[@]}" | sed -e 's/\\|$//'
          )"'\)\s*}}';
                filter1=(grep -e "${keys_rex}")
            }
        };
        declare -a filter2=(sed -e 's/^//');
        declare expr esc_val flags;
        declare -i ix;
        for ix in "${!ESC_KEYS[@]}";
        do
            ${OPT_SINGLE} || flags+=g;
            ${OPT_FIRST} && expr="^\s*";
            expr+='{{\s*'"${ESC_KEYS[$ix]}"'\s*}}';
            esc_val="${ESC_VALS[$ix]}";
            [[ -n "${esc_val}" ]] && {
                filter2+=(-e "s/${expr}/${esc_val}/${flags}");
                continue
            };
            filter2+=(-e "s/\\s*${expr}\\s*\$//${flags}" -e "s/${expr}\\s*//${flags}");
        done;
        printf -- '%s\n' "${ARG_TEXT[@]}" | "${filter1[@]}" | "${filter2[@]}"
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
            sed -e "${expression}" -e 's/^\s\+$//' <<< "${t}";
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
            sed -e 's/^\s\{0,'$((offset - 1))'\}//' -e 's/^\s\+$//' <<< "${t}";
        done
    }
    uniq_ordered ()
    {
        declare -a txt=("${@}");
        [[ ${#txt[@]} -gt 0 ]] || txt=("$(cat)");
        declare -a revfilter=(cat);
        printf -- '%s\n' "${txt[@]}" | "${revfilter[@]}" | cat -n | sort -k2 -k1n | uniq -f1 | sort -nk1,1 | cut -f2- | "${revfilter[@]}"
    }
  # {{/ SHLIB_CMDS }}
  # {{ SHLIB_MAPPER }}
    declare -A SHLIB_MAPPER=(
      ['log-err']='log_err'
      ['log-fatal']='log_fatal'
      ['log-info']='log_info'
      ['log-warn']='log_warn'
      ['sed-escape']='sed_escape'
      ['shlib-testblock-shlib-text-tpl']='shlib_testblock_shlib_text_tpl'
      ['shlib-text-tpl']='shlib_text_tpl'
      ['src-build-annotate']='src_build_annotate'
      ['src-build-bin']='src_build_bin'
      ['src-build-raw']='src_build_raw'
      ['src-build-test']='src_build_test'
      ['src-build-tmpdir']='src_build_tmpdir'
      ['tag-list-all']='tag_list_all'
      ['tag-nodes']='tag_nodes'
      ['tag-nodes-body']='tag_nodes_body'
      ['tag-nodes-merge']='tag_nodes_merge'
      ['tag-nodes-rm']='tag_nodes_rm'
      ['tag-nodes-update']='tag_nodes_update'
      ['tag-positions']='tag_positions'
      ['text-offset']='text_offset'
      ['text-strip']='text_strip'
      ['uniq-ordered']='uniq_ordered'
    )
    [[ -n "${1+x}" ]] || {
      log_err "Command required."
      exit 2
    }
    [[ -n "${SHLIB_MAPPER[${1}]+x}" ]] || {
      log_err "Invalid command: '${1}'"
      exit 2
    }

    local -r THE_CMD="${SHLIB_MAPPER[${1}]}"; shift
    "${THE_CMD}" "${@}"; exit $?
  # {{/ SHLIB_MAPPER }}
)

if ! (return 0 &>/dev/null); then
  # In bash `return` is only allowed in functions and sourced files,
  # so running as executable script.
  # Reference: https://stackoverflow.com/a/28776166

  SHLIB_LOG_TOOLNAME="$(basename -- "${BASH_SOURCE[@]}")" \
    shlib_do "${@}"

  exit "${?}"

  #
  # Code here is prevented from evaluation
  #

  # {{ SHLIB_KEEP = SHLIB_TEMPLATE }} {{/ SHLIB_KEEP }}
fi
