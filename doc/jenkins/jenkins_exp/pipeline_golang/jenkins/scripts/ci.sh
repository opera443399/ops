#!/bin/bash
#
# 2018/1/17

print_info() {
  echo "[I] -----------------> $1"
}

print_usage() {
  cat <<_EOF

usage:
    $0 [fix|build|deploy]

_EOF
}

case $1 in
fix|build|deploy)
    print_info $1" "$2
    ;;
  *)
    print_usage
    ;;
esac
