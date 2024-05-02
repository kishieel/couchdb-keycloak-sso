#!/usr/bin/env bash

source scripts/fail.sh

# Generate self-signed certificates
mkcert -cert-file nginx/certs/server.crt -key-file nginx/certs/server.key oblivio.localhost \*.oblivio.localhost || fail "Certificate generation failed"

# Change the ownership of the certificates
sudo chown -R 1001:root nginx/certs/server.*
