#!/bin/bash
################################################################################
# docker_nat_cleaner.sh - Clean up iptables rules after a docker crash
# Author: Dennis Walters
# Version 0.1.0
################################################################################

defined() {
  [ -n "${1}" ]
}

die() {
  echo "${@}" >&2
  exit 255
}

i_am_groot() {
  [ "$(whoami)" = 'root' ]
}

ipt() {
  defined "${@}" || die "Nothing passed to ipt"

  if i_am_groot
  then
    iptables ${@}
  else
    sudo iptables ${@}
  fi
}

ips_for_port() {
  defined "${1}" || die "no port passed to ips_for_port"

  ipt -t nat -S DOCKER | grep ":${1}" | awk '{print $NF}' | cut -d : -f 1
}

get_bad_ip() {
  defined "${1}" || die "no port passed to get_bad_ip"

  ips_for_port "${1}" | head -n 1
}

get_bad_rules() {
  defined "${1}" || die "no IP passed to get_bad_rules"

  local bad_ip="${1}"
  local nat_rule=""
  
  ipt -t nat -S | grep "${bad_ip}" | while read nat_rule
  do
    echo "-t nat ${nat_rule}"
  done
  ipt -S | grep "${bad_ip}"
}

delete_rule() {
  defined "${@}" || die "nothing passed to delete_rule"

  echo "Deleting rule '${@}'"
  ipt $(echo "${@}" | sed -e 's/-A /-D /')
}

should_clean_up() {
  defined "${1}" || die "no port passed to should_clean_up"

  [ $(ips_for_port "${1}" | wc -l) -gt 1 ]
}

main() {
  local bad_port="${1}"

  defined "${bad_port}" || die "usage: ${0} PORT"

  should_clean_up "${bad_port}" || die "There is only one IP target for port ${bad_port}"

  get_bad_rules $(get_bad_ip "${bad_port}") | while read rule
  do
    delete_rule "${rule}"
  done
}

main ${@}
