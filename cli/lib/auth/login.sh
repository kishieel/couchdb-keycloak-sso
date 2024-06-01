#!/bin/bash

set -e -o pipefail

help() {
  cat << EOF | sed 's/^ \{4\}//'
    cdb auth login: Initiates the authorization process for CLI access to the CouchDB instance.

    Usage:
      cdb auth login

    Commands:
      help  Displays this help message.

    Options:
      --help, -h  Displays this help message.

    For more information on a specific command, type 'cdb auth login --help'.
EOF
}

login() {
  local oidc_config; oidc_config=$(get_oidc_config)
  local auth_endpoint; auth_endpoint=$(get_auth_endpoint "$oidc_config")
  local token_endpoint; token_endpoint=$(get_token_endpoint "$oidc_config")
  local state; state=$(get_state)
  local code_verifier; code_verifier=$(get_code_verifier)
  local code_challenge; code_challenge=$(get_code_challenge "$code_verifier")
  local code_challenge_method; code_challenge_method=$(get_code_challenge_method)
  local auth_url; auth_url=$(get_auth_url "$auth_endpoint" 'couchdb-cli' 'http://localhost:8080' 'openid+couchdb+profile+email' "$state" "$code_challenge" "$code_challenge_method")

  print_auth_url "$auth_url"

  local code; code=$(create_listener)
  local credentials; credentials=$(get_credentials "$token_endpoint" 'authorization_code' "$code" 'couchdb-cli' 'http://localhost:8080' "$code_verifier")

  if [ -z "$credentials" ]; then
    echo "Failed to authenticate. Please try again."
    exit 1
  fi

  local name; name=$(get_name "$credentials")
  local email; email=$(get_email "$credentials")

  save_credentials "$credentials" "${HOME}/.config/cdb"

  echo "Successfully authenticated as ${name} <${email}>."
}

main() {
  case $1 in
    help | --help | -h) help;;
    *) login "$1";;
  esac
}

main "$@"
