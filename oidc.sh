#!/usr/bin/env bash

#AUTHENTICATION_URL='https://auth.oblivio.localhost/o/oauth2/sign_in?rd=http://localhost:8080'

AUTHORIZATION_ENDPOINT=$(curl -s 'https://auth.oblivio.localhost/realms/master/.well-known/openid-configuration' | jq -r '.authorization_endpoint')
OAUTH2_RESPONSE_TYPE='code'
OAUTH2_CLIENT_ID='oauth2-proxy'
OAUTH2_REDIRECT_URI='http://localhost:8080'
OAUTH2_SCOPE='openid+email+profile'
OAUTH2_STATE=$(head -c 16 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9')
OAUTH2_CODE_VERIFIER=$(head -c 40 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9')
OAUTH2_CODE_CHALLENGE=$(echo -n "$OAUTH2_CODE_VERIFIER" | sha256sum | awk '{print $1}' | base64 | tr -dc 'a-zA-Z0-9')
OAUTH2_CODE_CHALLENGE_METHOD='S256'

AUTHENTICATION_URL="${AUTHORIZATION_ENDPOINT}?response_type=${OAUTH2_RESPONSE_TYPE}&client_id=${OAUTH2_CLIENT_ID}&redirect_uri=${OAUTH2_REDIRECT_URI}&scope=${OAUTH2_SCOPE}&state=${OAUTH2_STATE}&code_challenge=${OAUTH2_CODE_CHALLENGE}&code_challenge_method=${OAUTH2_CODE_CHALLENGE_METHOD}"

echo ""
echo "Open the following URL in your browser:"

echo ""
echo "${AUTHENTICATION_URL}"

#xdg-open "${AUTHENTICATION_URL}"

echo ""
echo "Waiting for authorization..."

#echo -e 'HTTP/1.1 200 OK\r\n' | nc -l -p 8080;

#AUTHENTICATION_RESPONSE=$()
#OAUTH2_CODE=$(echo "$AUTHENTICATION_RESPONSE" | grep -oP 'code=\K[^&]*')
#echo "Authorization code: ${OAUTH2_CODE}"

#AUTHORIZATION_ENDPOINT=$(curl -s 'https://auth.oblivio.localhost/realms/master/.well-known/openid-configuration' | jq -r '.authorization_endpoint')
#OAUTH2_RESPONSE_TYPE='code'
#OAUTH2_CLIENT_ID='oauth2-proxy'
#OAUTH2_REDIRECT_URI='http://localhost:8080'
#OAUTH2_SCOPE='openid+email+profile'
#OAUTH2_STATE=$(head -c 16 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9')
#OAUTH2_CODE_VERIFIER=$(head -c 40 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9')
#OAUTH2_CODE_CHALLENGE=$(echo -n "$OAUTH2_CODE_VERIFIER" | sha256sum | awk '{print $1}' | base64 | tr -dc 'a-zA-Z0-9')
#OAUTH2_CODE_CHALLENGE_METHOD='S256'
#
#AUTHENTICATION_URL="${AUTHORIZATION_ENDPOINT}?response_type=${OAUTH2_RESPONSE_TYPE}&client_id=${OAUTH2_CLIENT_ID}&redirect_uri=${OAUTH2_REDIRECT_URI}&scope=${OAUTH2_SCOPE}&state=${OAUTH2_STATE}&code_challenge=${OAUTH2_CODE_CHALLENGE}&code_challenge_method=${OAUTH2_CODE_CHALLENGE_METHOD}"

# ?state=YvmIyWBsqETJRhmHCxQ
# &session_state=242fdbf0-1046-4481-9e71-4188a20f12de
# &iss=https%3A%2F%2Fauth.oblivio.localhost%2Frealms%2Fmaster
# &code=28216a0e-b09e-418d-862a-17b7fd8a0f57.242fdbf0-1046-4481-9e71-4188a20f12de.b54fc283-a927-412b-ab17-ef5ee0bdba11

# https://accounts.google.com
# /o/oauth2/auth
# ?response_type=code
# &client_id=32555940559.apps.googleusercontent.com
# &redirect_uri=http%3A%2F%2Flocalhost%3A8085%2F
# &scope=openid+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fuserinfo.email+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fcloud-platform+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fappengine.admin+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fsqlservice.login+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fcompute+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Faccounts.reauth
# &state=yLXWgJrJOmi6BcTbAiu7qeAaYiT2MQ
# &access_type=offline
# &code_challenge=Qr0wAItvQaK9uh0c2kfk7xuPuxAljcpUt8VO4VcdQZs
# &code_challenge_method=S256

#while [ ! -f output.txt ]; do
#  sleep 1
#done

#REDIRECT_URI='https://auth.oblivio.localhost/oauth2/callback'
#
#https://auth.oblivio.localhost/auth/realms/master/protocol/openid-connect/auth?client_id=<CLIENT_ID>&response_type=code&redirect_uri=https://auth.oblivio.localhost/&scope=openid
#

#AUTHENTICATION_URL="https://auth.oblivio.localhost/realms/master/protocol/openid-connect/auth?client_id=oauth2-proxy&response_type=code&redirect_uri=https://auth.oblivio.localhost/&scope=openid+email+profile"
#
#echo "Open the following URL in your browser:"
#echo "${AUTHENTICATION_URL}"
#
#echo "Waiting for authorization code..."
#
rm -f /tmp/oidc_listener
mkfifo /tmp/oidc_listener
trap "rm -f /tmp/oidc_listener" EXIT

cat /tmp/oidc_listener | nc -l 8080 > >(
  export REQUEST=
  while read line
  do
    line=$(echo "$line" | tr -d '[\r\n]')
    if echo "$line" | grep -qE '^GET /'
    then
      REQUEST=$(echo "$line" | cut -d ' ' -f2)
    elif [ "x$line" = x ]
    then
      HTTP_200="HTTP/1.1 200 OK"
      HTTP_LOCATION="Location:"
      HTTP_404="HTTP/1.1 404 Not Found"

      if echo $REQUEST | grep -qE '^/'
      then
        ACCESS_TOKEN=$(echo "$REQUEST" | sed -n 's/^.*access_token=\([^&]*\).*$/\1/p')
        echo AUTHORIZATION_CODE=$(echo "$REQUEST" | sed -n 's/^.*code=\([^&]*\).*$/\1/p') >/tmp/oidc_code
        HTML="<html><head><body>You can close this window.</body><script>window.close();</script></html>"
        printf "%s\n%s %s\n\n%s\n" "$HTTP_200" "$HTTP_LOCATION" $REQUEST $HTML > /tmp/out
        exit 0
      fi
    fi
  done
  exit 1
)
#
#cat /tmp/oidc_code
