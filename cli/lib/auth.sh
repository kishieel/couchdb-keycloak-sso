#!/usr/bin/env bash

set -e -o pipefail

ROOT_DIR="$(dirname "$0")/.."
LIB_DIR="$ROOT_DIR/lib"

show_help() {
  cat << EOF | sed 's/^ \{4\}//'
    cdb auth: A command-line tool for authorizing users to access a CouchDB instance.

    Usage:
      couchdb auth <command>

    Commands:
      login   Initiates the authorization process for CLI access to the CouchDB instance.
      logout  Terminates the current session, revoking CLI access to the CouchDB instance.

    Examples:
      cdb auth login
      cdb auth logout

    For more information on a specific command, type 'cdb auth <command> --help'.
EOF
}

case $1 in
  login | logout)
    cmd="$1"
    set -- "${@:2}"

    # shellcheck source=../auth/login.sh
    # shellcheck source=../auth/logout.sh
    source "$LIB_DIR/auth/$cmd.sh"
  ;;

  help | --help | -h)
    show_help
  ;;

  *)
    if [ -n "$1" ]; then
      echo -e "Unknown command: $1\n"
    fi

    show_help
    exit 1
  ;;
esac
