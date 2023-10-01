uniq_ordered() {
  # TODO: cleanup and add -r option
  declare -a txt=("${@}")
  [[ ${#txt[@]} -gt 0 ]] || txt=("$(cat)")

  declare -a revfilter=(cat)
  # revfilter=(tac)

  # https://unix.stackexchange.com/a/194790
  printf -- '%s\n' "${txt[@]}" | "${revfilter[@]}" \
  | cat -n | sort -k2 -k1n | uniq -f1 | sort -nk1,1 | cut -f2- \
  | "${revfilter[@]}"
}
