#!/usr/bin/env bash

. "$(dirname -- "${0}")/../tmp/build.annotated.sh"

( :
  echo 'TEST_TPL'
  echo '========'

  declare -a TEXTS=("
    Hello, {{ NAME }}! How are you {{ NAME }}?
      Just a line.
  " "
    {{ NAME }}, how are you? Nice weather, {{ NAME }}!
  ")
  declare -i ix; for ix in "${!TEXTS[@]}"; do
    TEXTS[$ix]="$(text_strip <<< "${TEXTS[$ix]}")"
  done

  declare name=Dude

  date >&2
  declare _; for _ in {1..1}; do
    printf '%s\n--------\n' 'ORIGINAL:'
    printf -- '%s\n' "${TEXTS[@]}"
    printf '%s\n-----------\n' 'FULL (ARGS):'
    shlib_text_tpl --kv NAME "${name}" -- "${TEXTS[@]}"
    printf '%s\n------------\n' 'ONLY (STDIN):'
    printf -- '%s\n' "${TEXTS[@]}" | shlib_text_tpl -o --kv NAME="${name}"
    printf '%s\n-------------\n' 'FIRST (STDIN):'
    printf -- '%s\n' "${TEXTS[@]}" | shlib_text_tpl -f --kv NAME="${name}"
    printf '%s\n--------------\n' 'SINGLE (STDIN):'
    printf -- '%s\n' "${TEXTS[@]}" | shlib_text_tpl -s --kv NAME="${name}"
    printf '%s\n--------------------\n' 'FIRST / ONLY (STDIN):'
    printf -- '%s\n' "${TEXTS[@]}" | shlib_text_tpl -f -o --kv NAME="${name}"
    { : # Corner cases
      # printf '%s\n--------------------\n' 'RM / ONLY (STDIN):'
      # printf -- '%s\n' "${TEXTS[@]}" | shlib_text_tpl -o --kv NAME=
      # printf '%s\n--------------------\n' 'HELP:'
      # shlib_text_tpl --help
      # printf '%s\n---------------\n' 'NO TEXT (STDIN):'
      # printf '' | shlib_text_tpl
      # printf '%s\n------------------\n' 'EMPTY TEXT (STDIN):'
      # shlib_text_tpl <<< ''
      # printf '%s\n------\n' 'ERRORS:'
      # shlib_text_tpl -f -f -o --only -s -s --help --inval1 --kv=inval2
      # shlib_text_tpl --kv inval3 <<< test
      # shlib_text_tpl --kv <<< test
    } # Corner cases
  done
  date >&2
)
