#!/bin/bash

set -e -o pipefail

help() {
  cat << EOF | sed 's/^ \{4\}//'
    cdb auth logout: Terminates the current session, revoking CLI access to the CouchDB instance.

    Usage:
      cdb auth logout

    Commands:
      help  Displays this help message.

    Options:
      --help, -h  Displays this help message.

    For more information on a specific command, type 'cdb auth logout --help'.
EOF
}

logout() {
    check_credentials

    local oidc_config; oidc_config=$(get_oidc_config)
    local end_session_endpoint; end_session_endpoint=$(get_end_session_endpoint "$oidc_config")
    local id_token; id_token=$(get_id_token)

    end_session "$end_session_endpoint" "$id_token"
    rm -f "$HOME/.config/cdb/credentials.json"

    echo "Successfully logged out."
}


main() {
  case $1 in
    help | --help | -h) help;;
    *) logout "$1";;
  esac
}

main "$@"
