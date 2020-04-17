#!/bin/bash
 
if [[ "${#}" -eq 0 ]]; then
  echo "[!] Pass 1 more more process names to find"
  return 1
fi
 
search_programs=( "${@}" )
 
declare -A name_shortcuts=(
  [web]='apache2'
)
 
declare -A program_check=(
  [apache2]='sudo service apache2 status'
)
 
declare -A program_start=(
  [apache2]='sudo service apache2 start'
)
 
check_if_running() {
  passed_program="${1}"
  if [[ -n "${program_check[$passed_program]}" ]]; then
    how_to_check=( "${program_check[$passed_program]}" )
  else
    how_to_check=( pid -s "${passed_program}" )
  fi
  echo -n "[!] Checking ${passed_program} using '${how_to_check[*]}': "
  if ${how_to_check[@]} &>/dev/null; then
    echo "Running"
    return 0
  else
    echo "Not Running"
    return 1
  fi
}
 
start_program() {
  passed_program="${1}"
  echo -n "[!] Attempting to start ${passed_program}: "
  if [[ -z "${program_start[$passed_program]}" ]]; then
    echo -e "FAIL\n[!] Unsure how to start ${passed_program}"
    return 1
  fi
 
  if ${program_start[${passed_program}]} &>/dev/null; then
    echo -e "OK\n[!] Successfully ran ${program_start[${passed_program}]}"
    return 0
  else
    echo -e "FAIL\n[!] Failed to run ${program_start[${passed_program}]}"
    return 1
  fi
}
 
for program in "${search_programs[@]}"; do
 if [[ -n "${name_shortcuts[$program]}" ]] ; then
  program="${name_shortcuts[$program]}"
 fi
 
  if ! check_if_running "${program}"; then
    if start_program "${program}"; then
      echo "[!] Waiting 5 seconds to check if it's running"
      sleep 5
      check_if_running "${program}"
    fi
  fi
done
