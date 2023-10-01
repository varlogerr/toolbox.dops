source_build_raw() (
  # Run `source_build_raw` content in subshell to avoid
  # environment pollution with function global state

  _iife() {
    declare -a SOURCES=("${@}")

    declare libonly_rex='\s*#\s*{{\s*DOPS_LIBONLY\s*/}}\s*'
    declare contents files_txt
    declare -a files

    declare contents_lines
    declare source; for source in "${SOURCES[@]}"; do
      source="$(realpath -m -- "${source}")"

      # Skip if already building in order to process only once
      [[ -n "${IN_BUILD+x}" ]] && grep -qFx "${source}" <<< "${IN_BUILD}" && continue

      # Add to bulding list
      IN_BUILD+="${IN_BUILD+$'\n'}${source}"

      # Result is preserved in a global variable in order to allow recursive function
      # call without subshell to keep BUILDING state
      if contents="$(cat -- "${source}" 2>/dev/null)"; then
        contents_lines="$(wc -l <<< "${contents}")"

        contents="$(grep -e '[^\s]\+' -m 1 -A "${contents_lines}" <<< "${contents}")"
        [[ -n "${contents}" ]] || continue

        if head -n 1 <<< "${contents}" | grep -qxe "${libonly_rex}"; then
          # Put LIBONLY behind DOPS_LIBONLY tag
          contents="$(tail -n +2 <<< "${contents}")"
          grep -qxe "${libonly_rex}" <<< "${RESULT}" || {
            contents='# {{DOPS_LIBONLY/}}'$'\n'"${contents}"
          }

          RESULT+="${RESULT+$'\n\n'}${contents}"
        else
          RESULT="${contents}${RESULT+$'\n\n'}${RESULT}"
        fi

        continue
      fi

      # Probably directory
      [[ -d "${source}" ]] || {
        echo "'${source}' must be a file or a directory." >&2
        continue
      }

      # Collect contents from files in the directory
      files_txt="$(find "${source}" -type f -name '*.sh' | sort -n)"
      [[ -n "${files_txt}" ]] || continue
      mapfile -t files <<< "${files_txt}"

      "${FUNCNAME[0]}" "${files[@]}" >/dev/null
    done

    [[ -n "${RESULT}" ]] && printf -- '%s\n' "${RESULT}"
    return 0
  }; _iife "${@}"; unset _iife
)
