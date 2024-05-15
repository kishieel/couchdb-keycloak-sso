#!/usr/bin/env bash

set -e -o pipefail

if [ ! -f "$HOME/.config/cdb/credentials.json" ]; then
  echo "No credentials found. Please authenticate first."
  exit 1
fi

CREDENTIALS=$(cat "$HOME/.config/cdb/credentials.json")
ACCESS_TOKEN=$(echo "${CREDENTIALS}" | jq -r '.access_token')
TOKEN_TYPE=$(echo "${CREDENTIALS}" | jq -r '.token_type')

DECODED_ACCESS_TOKEN=$(echo "${ACCESS_TOKEN}" | cut -d "." -f2 | sed 's/$/====/' | fold -w 4 | sed '$ d' | tr -d '\n' | openssl enc -base64 -d -A)
ACCESS_TOKEN_EXPIRES_AT=$(echo "${DECODED_ACCESS_TOKEN}" | jq -r '.exp')
CURRENT_TIME=$(date +%s)

if [ "${ACCESS_TOKEN_EXPIRES_AT}" -lt "${CURRENT_TIME}" ]; then
  REFRESH_TOKEN=$(echo "${CREDENTIALS}" | jq -r '.refresh_token')
  DECODED_REFRESH_TOKEN=$(echo "${REFRESH_TOKEN}" | cut -d "." -f2 | sed 's/$/====/' | fold -w 4 | sed '$ d' | tr -d '\n' | openssl enc -base64 -d -A)
  REFRESH_TOKEN_EXPIRES_AT=$(echo "${DECODED_REFRESH_TOKEN}" | jq -r '.exp')

  if [ "${REFRESH_TOKEN_EXPIRES_AT}" -lt "${CURRENT_TIME}" ]; then
    echo "Your session has expired. Please re-authenticate."
    exit 1
  fi

  OIDC_CONFIG=$(curl -s 'https://auth.oblivio.localhost/realms/master/.well-known/openid-configuration')
  TOKEN_ENDPOINT=$(echo "$OIDC_CONFIG" | jq -r '.token_endpoint')

  GRANT_TYPE='refresh_token'
  CLIENT_ID='couchdb-cli'
  SCOPE='openid+couchdb'

  CREDENTIALS=$(curl -s -X POST "${TOKEN_ENDPOINT}" -d "grant_type=${GRANT_TYPE}" -d "refresh_token=${REFRESH_TOKEN}" -d "client_id=${CLIENT_ID}" -d "scope=${SCOPE}")
  echo "${CREDENTIALS}" > "${HOME}/.config/cdb/credentials.json"

  ACCESS_TOKEN=$(echo "${CREDENTIALS}" | jq -r '.access_token')
  TOKEN_TYPE=$(echo "${CREDENTIALS}" | jq -r '.token_type')
fi

curl "$@" -H "Authorization: ${TOKEN_TYPE} ${ACCESS_TOKEN}"
