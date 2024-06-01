#!/bin/bash

set -e -o pipefail
source "$LIB_DIR/utils/oidc.sh"

main() {
  check_credentials

  local access_token; access_token=$(get_access_token)
  local token_type; token_type=$(get_token_type)
  local decoded_access_token; decoded_access_token=$(decode_access_token "$access_token")
  local access_token_expires_at; access_token_expires_at=$(get_access_token_expires_at "$decoded_access_token")
  local current_time; current_time=$(date +%s)

  if [ "${access_token_expires_at}" -lt "${current_time}" ]; then
    local refresh_token; refresh_token=$(get_refresh_token)
    local decoded_refresh_token; decoded_refresh_token=$(decode_refresh_token "$refresh_token")
    local refresh_token_expires_at; refresh_token_expires_at=$(get_refresh_token_expires_at "$decoded_refresh_token")

    if [ "${refresh_token_expires_at}" -lt "${current_time}" ]; then
      echo "Your session has expired. Please re-authenticate."
      exit 1
    fi

    local oidc_config; oidc_config=$(get_oidc_config)
    local token_endpoint; token_endpoint=$(get_token_endpoint "$oidc_config")

    refresh_access_token "$token_endpoint" "$refresh_token"

    access_token=$(get_access_token)
    token_type=$(get_token_type)
  fi

  curl "$@" -H "Authorization: ${token_type} ${access_token}"
}

main "$@"
