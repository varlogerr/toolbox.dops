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
      [bin_tpl]="${SELF_DIR}/src/shlib.tpl.sh"
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

  declare TARGET_RAW="${TARGET[tmp_dir]}/build.raw.sh"
  declare TARGET_ANNOTATED="${TARGET[tmp_dir]}/build.annotated.sh"
  declare TARGET_TEST="${TARGET[tmp_dir]}/build.test.sh"

  : \
  && src_build_tmpdir "${TARGET[tmp_dir]}" \
  && src_build_raw "${TARGET_RAW}" "${SOURCES[@]}" \
  && src_build_annotate "${TARGET_ANNOTATED}" "${TARGET_RAW}" \
  && src_build_test "${TARGET_TEST}" "${TARGET_ANNOTATED}" "${TESTS[@]}" \
  && ${OPTS[test]} && exit || true \
  && _src_build_self SHLIB_QBSw4_MODULES_TPL "${TARGET_RAW}" "${OPTS[noself]}" \
  && src_build_bin "${TARGET[bin_file]}" "${TARGET[bin_tpl]}" "${TARGET_ANNOTATED}"


  exit

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
    . "$(dirname -- "${SELF_DIR}")/src/lib/basic.sh"
    declare f; for f in "$(dirname -- "${SELF_DIR}")/src/lib/"*.sh; do
      . "${f}"
    done
  # {{/ SHLIB_QBSw4_MODULES_TPL }}
}; _iife; unset _iife
