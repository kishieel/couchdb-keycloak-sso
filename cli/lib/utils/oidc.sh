#!/bin/bash

set -e -o pipefail

check_credentials() {
  if [ ! -f "$HOME/.config/cdb/credentials.json" ]; then
    echo "No credentials found. Please authenticate first."
    exit 1
  fi
}

get_oidc_config() {
  curl -s 'https://auth.oblivio.localhost/realms/master/.well-known/openid-configuration'
}

get_token_endpoint() {
  local oidc_config="$1"
  echo "$oidc_config" | jq -r '.token_endpoint'
}

get_auth_endpoint() {
  local oidc_config="$1"
  echo "$oidc_config" | jq -r '.authorization_endpoint'
}

get_end_session_endpoint() {
  local oidc_config="$1"
  echo "$oidc_config" | jq -r '.end_session_endpoint'
}

get_token_type() {
  local credentials; credentials=$(cat "$HOME/.config/cdb/credentials.json")
  echo "${credentials}" | jq -r '.token_type'
}

get_access_token() {
  local credentials; credentials=$(cat "$HOME/.config/cdb/credentials.json")
  echo "${credentials}" | jq -r '.access_token'
}

decode_access_token() {
  local access_token="$1"
  echo "${access_token}" | cut -d "." -f2 | sed 's/$/====/' | fold -w 4 | sed '$ d' | tr -d '\n' | openssl enc -base64 -d -A
}

get_access_token_expires_at() {
  local decoded_access_token="$1"
  echo "${decoded_access_token}" | jq -r '.exp'
}

get_refresh_token() {
  local credentials; credentials=$(cat "$HOME/.config/cdb/credentials.json")
  echo "${credentials}" | jq -r '.refresh_token'
}

decode_refresh_token() {
  local refresh_token="$1"
  echo "${refresh_token}" | cut -d "." -f2 | sed 's/$/====/' | fold -w 4 | sed '$ d' | tr -d '\n' | openssl enc -base64 -d -A
}

get_refresh_token_expires_at() {
  local decoded_refresh_token="$1"
  echo "${decoded_refresh_token}" | jq -r '.exp'
}

get_id_token() {
  local credentials; credentials=$(cat "$HOME/.config/cdb/credentials.json")
  echo "${credentials}" | jq -r '.id_token'
}

refresh_access_token() {
  local token_endpoint="$1"
  local refresh_token="$2"
  local client_id='couchdb-cli'
  local scope='openid+couchdb+profile+email'
  local credentials; credentials=$(curl -s -X POST "${token_endpoint}" -d "grant_type=refresh_token" -d "refresh_token=${refresh_token}" -d "client_id=${client_id}" -d "scope=${scope}")

  echo "${credentials}" > "${HOME}/.config/cdb/credentials.json"
}

get_state() {
  head -c 16 /dev/urandom | openssl enc -base64 | tr -dc 'a-zA-Z0-9'
}

get_code_verifier() {
  openssl rand -base64 60 | tr -d '\n' | tr '/+' '_-' | tr -d '='
}

get_code_challenge() {
  echo -n "$1" | openssl dgst -sha256 -binary | openssl enc -base64 | tr '/+' '_-' | tr -d '='
}

get_code_challenge_method() {
  echo 'S256'
}

get_auth_url() {
  local auth_endpoint="$1"
  local client_id="$2"
  local redirect_uri="$3"
  local scope="$4"
  local state="$5"
  local code_challenge="$6"
  local code_challenge_method="$7"

  echo "${auth_endpoint}?response_type=code&client_id=${client_id}&redirect_uri=${redirect_uri}&scope=${scope}&state=${state}&code_challenge=${code_challenge}&code_challenge_method=${code_challenge_method}"
}

print_auth_url() {
  echo "Open the following URL in your browser:"
  echo ""
  echo "$1"
  echo ""
  echo "Waiting for authorization..."
}

create_listener() {
  rm -f /tmp/oidc_listener
  mkfifo /tmp/oidc_listener
  trap "rm -f /tmp/oidc_listener" EXIT

  local success_response="HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nContent-Length: 75\r\nConnection: close\r\n\r\n<p>Authentication was successful.</p><p>You can now close your browser.</p>"
  echo -en "$success_response" | nc -l -p 8080 > /tmp/oidc_listener &

  local code

  while IFS= read -r line; do
    if [[ "$line" == *"GET "*"code="* ]]; then
      code=$(echo "$line" | sed -n 's/^.*code=\([^&[:space:]]*\).*$/\1/p')
      break
    fi
  done < /tmp/oidc_listener

  echo "$code"
}

get_credentials() {
  local token_endpoint="$1"
  local grant_type="$2"
  local code="$3"
  local client_id="$4"
  local redirect_uri="$5"
  local code_verifier="$6"

  curl -s -X POST "${token_endpoint}" -d "grant_type=${grant_type}" -d "code=${code}" -d "client_id=${client_id}" -d "redirect_uri=${redirect_uri}" -d "code_verifier=${code_verifier}"
}

save_credentials() {
  local credentials="$1"
  local config_dir="$2"

  mkdir -p "${config_dir}"
  echo "${credentials}" > "${config_dir}/credentials.json"
}

get_name() {
  echo "$1" | cut -d "." -f2 | sed 's/$/====/' | fold -w 4 | sed '$ d' | tr -d '\n' | openssl enc -base64 -d -A | jq -r '.name'
}

get_email() {
  echo "$1" | cut -d "." -f2 | sed 's/$/====/' | fold -w 4 | sed '$ d' | tr -d '\n' | openssl enc -base64 -d -A | jq -r '.email'
}

end_session() {
  local end_session_endpoint="$1"
  local id_token_hint="$2"

  curl -s -o /dev/null -X POST "${end_session_endpoint}" -d "id_token_hint=${id_token_hint}"
}
