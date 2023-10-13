src_build_raw() {
  # shellcheck disable=SC2034
  declare SHLIB_LOG_TOOLNAME=build.raw

  declare TARGET="${1}"
  declare -a SOURCES=("${@:2}")
  declare -i RC=0
  declare PROCESSING RAW_TAGS RAW_DEFS

  log_info "Generating raw source ..."

  _iife_build_raw() {
    # shellcheck disable=SC2030
    declare -a SOURCES=("${@}")

    declare dir_sources_txt content
    declare -a dir_sources
    declare fnames fdefs tags
    declare source; for source in "${SOURCES[@]}"; do
      grep -qFx -- "${source}" <<< "${PROCESSING}" && {
        log_info "Skipping:   '${source}'"
        continue
      }

      PROCESSING+="${PROCESSING+$SHLIB_NL}${source}"
      log_info "Processing: '${source}' ..."

      if [[ -d "$(realpath -- "${source}" 2> /dev/null)" ]]; then
        # Recurse for directory

        dir_sources_txt="$(find "${source}" -type f -name '*.sh' | sort -n)"
        [[ -n "${dir_sources_txt}" ]] || {
          log_warn "Empty dir:  '${source}'."
          continue
        }
        mapfile -t dir_sources <<< "${dir_sources_txt}"

        "${FUNCNAME[0]}" "${dir_sources[@]}"; RC=$?
      elif content="$(cat -- "${source}" 2>/dev/null)"; then
        # It's a file

        tags="$(_src_build_text_tags <<< "${content}")"
        [[ -n "${RAW_TAGS}" ]] && [[ -n "${tags}" ]] && RAW_TAGS+="${SHLIB_NL}"
        RAW_TAGS+="${tags}"

        fnames="$(_src_build_file_fnames "${source}")" || { RC=${?}; continue; }
        fdefs="$(_src_build_file_fdefs "${source}" "${fnames}")" || { RC=${?}; continue; }
        [[ -n "${RAW_DEFS}" ]] && [[ -n "${fdefs}" ]] && RAW_DEFS+="${SHLIB_NL}"
        RAW_DEFS+="${fdefs}"
      else
        log_err "Can't read:  '${source}'."
        RC=1
        continue
      fi

      log_info "Processed:  '${source}'."
    done

    return ${RC}
  }
  # shellcheck disable=SC2031
  _iife_build_raw "${SOURCES[@]}"; RC=$?; unset _iife_build_raw

  declare tags; tags="$(tag_list_all "${RAW_TAGS}")" \
  && RAW_TAGS="$(while read -r t; do
    tag_nodes "${t}" "${RAW_TAGS}" | tag_nodes_merge "${t}"
  done <<< "${tags}")"

  log_info "Writing: '${TARGET}'"
  printf -- '%s%s' \
    "${RAW_TAGS}" \
    "${RAW_DEFS+$SHLIB_NL}${RAW_DEFS}" \
  | tee -- "${TARGET}" >/dev/null || {
    log_err "Can't write: '${TARGET}'"
    RC=1
  }

  log_info "Generated raw source."

  return ${RC}
}

_src_build_self() {
  # shellcheck disable=SC2034
  declare SHLIB_LOG_TOOLNAME=build.self

  declare target_tag="${1}"
  declare source="${2}"
  declare noself="${3}"
  declare -i RC=0

  ${noself} && {
    log_info "Skipping patching self."
    return 0
  }

  log_info "Patching self ..."

  # TODO: Implement building self

  log_info "Patched self."
}

src_build_bin() {
  # shellcheck disable=SC2034
  declare SHLIB_LOG_TOOLNAME=build.bin

  declare target="${1}"
  declare template="${2}"
  declare source="${3}"
  declare -i RC=0

  log_info "Building bin ..."

  declare source_txt; source_txt="$(cat -- "$source")"
  declare template_txt; template_txt="$(tag_nodes_rm SHLIB__SELFDOC < "$template")"
  declare template_tags_txt; template_tags_txt="$(tag_list_all <<< "${template_txt}")"

  declare -a template_tags
  [[ -n "${template_tags_txt}" ]] && mapfile -t template_tags <<< "${template_tags_txt}"

  declare -A block
  declare tt; for tt in "${template_tags[@]}"; do
    block[source]="$(
      tag_nodes "${tt}" <<< "${source_txt}"
    )" && block[source]="${SHLIB_NL}${block[source]}" || continue

    log_info "Processing block: '${tt}'"

    source_txt="$(tag_nodes_rm "${tt}" <<< "${source_txt}")"
    block[tpl]="$(tag_nodes "${tt}" <<< "${template_txt}")"
    block[update]="$(tag_nodes_merge "${tt}" "${block[tpl]}${block[source]}" | tag_nodes_body "${tt}")"

    template_txt="$(tag_nodes_update "${tt}" "${block[update]}" <<< "${template_txt}")"
  done

  declare -A block
  declare tag=SHLIB_CMDS
  if block[old]="$(tag_nodes "${tag}" <<< "${template_txt}")"; then
    log_info "Processing block: '${tag}'"

    block[update]="$(tag_nodes_update "${tag}" "${source_txt}" <<< "${block[old]}" | tag_nodes_body "${tag}")"
    template_txt="$(tag_nodes_update "${tag}" "${block[update]}" <<< "${template_txt}")"
  fi

  declare -A block
  declare tag=SHLIB_MAPPER
  while block[old]="$(tag_nodes "${tag}" <<< "${template_txt}")"; do
    declare fnames; fnames="$(
      while read -r func; do
        unset -f  "${func}"
      done <<< "$(declare -F | rev | cut -d' ' -f1 | rev)"

      # shellcheck disable=SC1090
      . <(printf -- '%s\n' "${source_txt}")
      declare -F | rev | cut -d' ' -f1 | rev \
      | grep -v '^\(_\|shlib_meta_docblock_\)' | grep '.'
    )" || break

    log_info "Processing block: '${tag}'"

    block[map]="declare -A ${tag}=("
    while read -r fname; do
      block[map]+="${SHLIB_NL}  ['${fname//_/-}']='${fname}'"
    done <<< "${fnames}"
    block[map]+="${SHLIB_NL})"

    # shellcheck disable=SC2016
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
    ')"

    template_txt="$(tag_nodes_update "${tag}" "${block[map]}" <<< "${template_txt}")"
    break
  done

  log_info "Writing: '${target}'"
  tee -- "${target}" <<< "${template_txt}" >/dev/null || {
    log_err "Can't write: '${target}'"
    RC=1
  }

  log_info "Built bin."
}

src_build_annotate() {
  # shellcheck disable=SC2034
  declare SHLIB_LOG_TOOLNAME=build.annotated

  declare target="${1}"
  declare source="${2}"

  log_info "Building annotated ..."

  log_info "Writing: '${target}'"
  tee -- "${target}" < "${source}" >/dev/null || {
    log_err "Can't write: '${target}'"
    RC=1
  }

  log_info "Built annotated."
}

src_build_test() {
  # shellcheck disable=SC2034
  declare SHLIB_LOG_TOOLNAME=build.test

  declare test_file="${1}"
  declare source="${2}"
  declare -a tests=("${@:3}")

  log_info "Testing ..."

  log_info "Tested."
}

src_build_tmpdir() {
  # shellcheck disable=SC2034
  declare SHLIB_LOG_TOOLNAME=build.tmpdir

  declare tmpdir="${1}"

  log_info "Creating tmp directory ..."
  log_info "Creating: '${tmpdir}' ..."
  mkdir -p -- "${tmpdir}" || {
    log_err "Can't create directory '${tmpdir}'."
    return 1
  }
  log_info "Created tmp directory."
}

_src_build_file_fnames() {
  declare file="${1}"

  (
    # Unset present until now functions
    while read -r func; do
      [[ -n "${func}" ]] && unset -f "${func}"
    done < <(declare -F | rev | cut -d' ' -f1 | rev)

    # Exit if stderr contains errors
    # shellcheck disable=SC1090
    . "${file}"
    declare -F | rev | cut -d' ' -f1 | rev
  ) || {
    log_err "Error sourcing: '${file}'"
    return 1
  }
}

_src_build_file_fdefs() {
  declare file="${1}"
  declare fnames="${2}"
  declare output

  [[ -n "${fnames}" ]] || return 0

  declare -i RC=0
  declare fname; while read -r fname; do
    output+="${output+$SHLIB_NL}$(
      # Exit if stderr contains errors
      # shellcheck disable=SC1090
      . "${file}" 3>&1 1>&2 2>&3 | grep '.' >&2 && exit 1
      declare -f "${fname}"
    )" || {
      log_err "Error retrieving func definition: '${file}'"
      RC=1
    }
  done <<< "${fnames}"

  declare ext_tag=SHLIB_EXT_CMDS
  declare nodes; nodes="$(tag_nodes "${ext_tag}" < "${file}")" && {
    output="$(
      tag_nodes_merge "${ext_tag}" <<< "${nodes}" \
      | tag_nodes_update "${ext_tag}" "${output}"
    )"
  }

  printf -- '%s' "${output}${output:+$SHLIB_NL}"

  return ${RC}
}


# shellcheck disable=SC2120
_src_build_text_tags() {
  declare text; text="${1-$(cat)}"
  declare tags; tags="$(
    tag_list_all "${text}" | grep -v ^SHLIB_EXT_CMDS | grep '^SHLIB_'
  )" || return

  [[ -n "${tags}" ]] || return 0

  while read -r t; do tag_nodes "${t}" "${text}"; done <<< "${tags}"
}








return


source_build_merge() {
  # shellcheck disable=SC2034
  declare SHLIB_LOG_TOOLNAME=build.merge
  declare IN_BUILD \
          RESULT_CODE
  declare -a MERGED \
             FAILED

  declare -a info_msg
  [[ ${#} -gt 0 ]] && {
    info_msg=("Merging:" "$(text_offset -t '  * ' -l 1 "${@}")")
  } || {
    info_msg=("Merging ...")
  }

  log_info "${info_msg[@]}"

  _iife() {
    declare -a SOURCES=("${@}")

    declare external_tag='SHLIB_EXT_CMDS'
    declare keep_tag='SHLIB_KEEP'
    declare contents files_txt
    declare -a files

    declare contents_lines
    declare source; for source in "${SOURCES[@]}"; do
      # Skip if already building in order to process only once
      [[ -n "${IN_BUILD+x}" ]] && grep -qFx "${source}" <<< "${IN_BUILD}" && {
        log_info "Skip merging ${source}"
        continue
      }

      # Add to bulding list
      IN_BUILD+="${IN_BUILD+${SHLIB_NL}}${source}"
      log_info "Merging ${source} ..."

      # Result is preserved in a global variable in order to allow recursive function
      # call without subshell to keep BUILDING state
      if contents="$(cat -- "${source}" 2>/dev/null)"; then
        contents_lines="$(wc -l <<< "${contents}")"

        contents="$(grep -e '[^\s]\+' -m 1 -A "${contents_lines}" <<< "${contents}")"
        [[ -n "${contents}" ]] || continue

        declare KEEP_BLOCK; KEEP_BLOCK="$(tag_nodes "${keep_tag}" "${contents}")" && {
          contents="$(tag_nodes_rm "${keep_tag}" "${contents}")"
          log_info "  ${keep_tag} tag extracted"
        }

        # External module
        if tag_positions "${external_tag}" "${contents}" >/dev/null; then
          contents="# {{ ${external_tag} }}${SHLIB_NL}$(
            tag_nodes_rm "${external_tag}" "${contents}"
          )${SHLIB_NL}# {{/ ${external_tag} }}"
          log_info "  ${external_tag} tag wrapper applied"
        fi

        [[ -n "${KEEP_BLOCK}" ]] && {
          log_info "  ${keep_tag} elevated"
          contents="$(printf -- '%s\n%s\n' "${KEEP_BLOCK}" "${contents}")"
        }

        RESULT_CODE+="${RESULT_CODE+${SHLIB_NL}${SHLIB_NL}}${contents}"
        MERGED+=("${source}")
        log_info "Merged  ${source}"

        continue
      fi

      # Probably directory
      [[ -d "${source}" ]] || {
        FAILED+=("${source}")
        log_warn "'${source}' must be a file or a directory."
        continue
      }

      # Collect contents from files in the directory
      files_txt="$(find "${source}" -type f -name '*.sh' | sort -n)"
      [[ -n "${files_txt}" ]] || continue
      mapfile -t files <<< "${files_txt}"

      "${FUNCNAME[0]}" "${files[@]}" >/dev/null
      log_info "Merged  ${source}"
    done

    external_body="$(tag_nodes_body "${external_tag}" "${RESULT_CODE}")"
    RESULT_CODE="$(tag_nodes_rm "${external_tag}" "${RESULT_CODE}")"

    RESULT_CODE="$(
      printf -- '# {{ %s }}\n%s\n# {{/ %s }}\n%s' \
        "${external_tag}" "$(
          text_offset "${external_body}"
        )" "${external_tag}" "${RESULT_CODE}"
    )"

    [[ -n "${RESULT_CODE}" ]] && printf -- '%s\n' "${RESULT_CODE}"
    return 0
  }; _iife "${@}"; unset _iife

  declare -a info_msg
  [[ ${#MERGED[@]} -gt 0 ]] && {
    log_info "Merged:" "$(text_offset -t '  * ' -l 1 "${MERGED[@]}")"
  }

  [[ ${#FAILED[@]} -gt 0 ]] && {
    log_err "Failed:" "$(text_offset -t '  * ' -l 1 "${FAILED[@]}")" "FAILURE"
    return 1
  }

  log_info "SUCCESS"
  return 0
}

source_build_raw() {
  declare SOURCE="${1}"

  declare external_tag='SHLIB_EXT_CMDS'
  declare keep_tag='SHLIB_KEEP'

  declare SHLIB_LOG_TOOLNAME=build.raw
  log_info "Building raw ..."

  log_info "${keep_tag} collecting ..."
  declare KEEP_BLOCK; KEEP_BLOCK="$(
    tag_nodes "${keep_tag}" "${SOURCE}"
  )" && {
    SOURCE="$(tag_nodes_rm "${keep_tag}" "${SOURCE}")"
    log_info "${keep_tag} collected"
  } || {
    log_info "${keep_tag} not detected"
  }

  log_info "${external_tag} collecting ..."
  declare EXTERNAL_BLOCK; EXTERNAL_BLOCK="$(
    set -o pipefail
    tag_nodes "${external_tag}" "${SOURCE}" \
    | tag_nodes_merge "${external_tag}"
  )" && {
    SOURCE="$(tag_nodes_rm "${external_tag}" "${SOURCE}")"
    log_info "${external_tag} collected"
  } || {
    log_info "${external_tag} not detected"
  }
  EXTERNAL_BLOCK="$(
    update="$(
      unset -f $(declare -F | rev | cut -d ' ' -f 1 | rev)
      . <(cat <<< "${EXTERNAL_BLOCK}")
      declare -f
    )"
    tag_nodes_update "${external_tag}" "${update}" "${EXTERNAL_BLOCK}"
  )"

  log_info "Getting func names ..."
  declare fnames_txt; fnames_txt="$(
    unset -f $(declare -F | rev | cut -d ' ' -f 1 | rev)
    . <(cat <<< "${SOURCE}")
    declare -F | rev | cut -d ' ' -f 1 | rev
  )" || {
    log_err "Can't get func names"
  }
  [[ -n "${fnames_txt}" ]] || {
    log_warn "No func names detected"
    return
  }
  declare -a fnames; mapfile -t fnames <<< "${fnames_txt}"
  log_info "Got func names"

  log_info "Getting func definitions ..."
  declare fdefs_txt; fdefs_txt="$(
    unset -f $(declare -F | rev | cut -d ' ' -f 1 | rev)
    . <(cat <<< "${SOURCE}")
    declare -f
  )" || {
    log_err "Can't get func definitions"
    return 1
  }
  declare -a fdefs; mapfile -t fdefs <<< "${fdefs_txt}"
  log_info "Got func definitions"

  (
    echo "${KEEP_BLOCK}"
    echo "${EXTERNAL_BLOCK}"
    printf -- '%s\n' "${fdefs[@]}"
  ) | text_strip

  log_info "SUCCESS"
}

_source_build_self() {
  declare BIN_FILE="${1}"
  declare DEST="${2}"
  declare TARGET_RAW="${3}"

  declare SHLIB_LOG_TOOLNAME=build.self
  log_info "Updating ${DEST} modules template ..."

  declare tpl_tag=SHLIB_QBSw4_MODULES_TPL

  declare DEST_CODE; DEST_CODE="$(cat -- "${DEST}")" || {
    log_err "Can't get ${DEST} code"
    exit 1
  }

  declare MODULES_CODE; MODULES_CODE="$(cat -- "${TARGET_RAW}")" || {
    log_err "Can't get ${TARGET_RAW} code"
    exit 1
  }

  declare positions; positions="$(tag_positions "${tpl_tag}" "${DEST_CODE}")" || {
    log_err "Can't get ${tpl_tag}"
    exit 1
  }
  [[ "$(wc -l <<< "${positions}")" -lt 2 ]] || {
    log_err "Only one ${tpl_tag} is allowed"
    exit 1
  }

  declare -A line=([start]="${positions%%:*}" [end]="${positions#*:}")

  [[ $(( line[end] - line[start])) -gt 1 ]] || {
    log_err "Minimum 1 line must present in ${tpl_tag}"
    exit 1
  }

  DEST_CODE="$(sed -e "$(( line[start] + 1 )),$(( line[end] - 1 ))d" <<< "${DEST_CODE}")"
  DEST_CODE+="${SHLIB_NL}#{{ ${tpl_tag} }}${SHLIB_NL}${MODULES_CODE}${SHLIB_NL}# {{/ ${tpl_tag} }}"

  (
    set -o pipefail
    tag_nodes_merge "${tpl_tag}" "${DEST_CODE}" | text_strip |  (set -x; tee "${SELF}" >/dev/null)
  ) || {
    log_err "Can't update ${SELF}"
    exit 1
  }

  log_info "Updated  ${SELF} modules template" "SUCCESS"
}
