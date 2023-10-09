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
