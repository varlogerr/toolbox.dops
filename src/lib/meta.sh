# {{ SHLIB_EXT_CMDS }} {{/ SHLIB_EXT_CMDS }}

# {{ SHLIB_KEEP = SHLIB_EXT_VARS }}
  declare -g SHLIB_META_PREFIX_8jHoB='#X;Oq/M$p8'
  declare -g _SHLIB_META_FNAME
# {{/ SHLIB_KEEP }}

shlib_meta_description() { _shlib_meta "${FUNCTION[0]}" "${@}"; }
shlib_meta_usage() { _shlib_meta "${FUNCTION[0]}" "${@}"; }
shlib_meta_rc() { _shlib_meta "${FUNCTION[0]}" "${@}"; }
shlib_meta_demo() { _shlib_meta "${FUNCTION[0]}" "${@}"; }
shlib_meta_more() { _shlib_meta "${FUNCTION[0]}" "${@}"; }

_shlib_meta() {
  declare upstream="${1}"; shift
  declare fname

  if [[ -n "${_SHLIB_META_FNAME+x}" ]]; then
    fname="${_SHLIB_META_FNAME}"
  elif [[ -n "${1+x}" ]]; then
    fname="${1}"; shift
  else
    echo "[${upstream}:err] FUNC_NAME is required." >&2
    return 2
  fi

  declare -a token=("${SHLIB_META_PREFIX_8jHoB}" "${upstream}" "${fname}")

  [[ -n "${1+x}" ]] && {
    shlib_assoc_put "${token[@]}" <<< "$(
      text_strip "${@}"
    )"
    return
  }

  shlib_assoc_get "${token[@]}"
}
