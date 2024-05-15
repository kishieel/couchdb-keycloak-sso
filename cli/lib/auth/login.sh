#!/usr/bin/env bash

set -e -o pipefail

show_help() {
  cat << EOF | sed 's/^ \{4\}//'
    cdb auth login: Initiates the authorization process for CLI access to the CouchDB instance.

    Usage:
      cdb auth login

    For more information on a specific command, type 'cdb auth login --help'.
EOF
}

login() {
  OIDC_CONFIG=$(curl -s 'https://auth.oblivio.localhost/realms/master/.well-known/openid-configuration')
  AUTH_ENDPOINT=$(echo "$OIDC_CONFIG" | jq -r '.authorization_endpoint')
  TOKEN_ENDPOINT=$(echo "$OIDC_CONFIG" | jq -r '.token_endpoint')

  GRANT_TYPE='authorization_code'
  RESPONSE_TYPE='code'
  REDIRECT_URI='http://localhost:8080'
  CLIENT_ID='couchdb-cli'
  SCOPE='openid+couchdb'

  STATE=$(head -c 16 /dev/urandom | openssl enc -base64 | tr -dc 'a-zA-Z0-9')
  CODE_VERIFIER=$(openssl rand -base64 60 | tr -d '\n' | tr '/+' '_-' | tr -d '=')
  CODE_CHALLENGE=$(echo -n "$CODE_VERIFIER" | openssl dgst -sha256 -binary | openssl enc -base64 | tr '/+' '_-' | tr -d '=')
  CODE_CHALLENGE_METHOD='S256'

  AUTH_URL="${AUTH_ENDPOINT}?response_type=${RESPONSE_TYPE}&client_id=${CLIENT_ID}&redirect_uri=${REDIRECT_URI}&scope=${SCOPE}&state=${STATE}&code_challenge=${CODE_CHALLENGE}&code_challenge_method=${CODE_CHALLENGE_METHOD}"

  echo "Open the following URL in your browser:"
  echo ""
  echo "${AUTH_URL}"
  echo ""
  echo "Waiting for authorization..."

  rm -f /tmp/oidc_listener
  mkfifo /tmp/oidc_listener
  trap "rm -f /tmp/oidc_listener" EXIT

  SUCCESS_RESPONSE="HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nContent-Length: 75\r\nConnection: close\r\n\r\n<p>Authentication was successful.</p><p>You can now close your browser.</p>"
  echo -en "$SUCCESS_RESPONSE" | nc -l -p 8080 > /tmp/oidc_listener &

  while IFS= read -r line; do
    if [[ "$line" == *"GET "*"code="* ]]; then
      CODE=$(echo "$line" | sed -n 's/^.*code=\([^&[:space:]]*\).*$/\1/p')
      break
    fi
  done < /tmp/oidc_listener

  CREDENTIALS=$(curl -s -X POST "${TOKEN_ENDPOINT}" -d "grant_type=${GRANT_TYPE}" -d "code=${CODE}" -d "client_id=${CLIENT_ID}" -d "redirect_uri=${REDIRECT_URI}" -d "code_verifier=${CODE_VERIFIER}")

  if [ -z "$CREDENTIALS" ]; then
    echo "Failed to authenticate. Please try again."
    exit 1
  fi

  ID_TOKEN=$(echo "${CREDENTIALS}" | jq -r '.id_token')
  DECODED_ID_TOKEN=$(echo "${ID_TOKEN}" | cut -d "." -f2 | sed 's/$/====/' | fold -w 4 | sed '$ d' | tr -d '\n' | openssl enc -base64 -d -A)
  NAME=$(echo "${DECODED_ID_TOKEN}" | jq -r '.name')
  EMAIL=$(echo "${DECODED_ID_TOKEN}" | jq -r '.email')

  mkdir -p "${HOME}/.config/cdb"
  echo "${CREDENTIALS}" > "${HOME}/.config/cdb/credentials.json"

  echo "Successfully authenticated as ${NAME} <${EMAIL}>."
}

case $1 in
  help | --help | -h)
    show_help
  ;;

  *)
    login "$1"
  ;;
esac
