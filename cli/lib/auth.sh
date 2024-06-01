#!/bin/bash

set -e -o pipefail
source "$LIB_DIR/utils/oidc.sh"

help() {
  cat << EOF | sed 's/^ \{4\}//'
    cdb auth: A command-line tool for authorizing users to access a CouchDB instance.

    Usage:
      couchdb auth <command>

    Commands:
      login   Initiates the authorization process for CLI access to the CouchDB instance.
      logout  Terminates the current session, revoking CLI access to the CouchDB instance.
      help    Displays this help message.

    Options:
      --help, -h  Displays this help message.

    Examples:
      cdb auth login
      cdb auth logout

    For more information on a specific command, type 'cdb auth <command> --help'.
EOF
}

main() {
  case $1 in
    login) shift; source "$LIB_DIR/auth/login.sh";;
    logout) shift; source "$LIB_DIR/auth/logout.sh";;
    help | --help | -h) help;;
    *)
      if [ -n "$1" ]; then echo -e "Unknown command: $1\n"; fi
      help
      exit 1
    ;;
  esac
}

main "$@"
