local authorization = ngx.var.http_authorization

if authorization ~= nil then
    return
end

local opts = {
    redirect_uri = "/callback",
    discovery = {
        issuer = "https://auth.oblivio.localhost/realms/master",
        authorization_endpoint = "https://auth.oblivio.localhost/realms/master/protocol/openid-connect/auth",
        end_session_endpoint = "https://auth.oblivio.localhost/realms/master/protocol/openid-connect/logout",
        token_endpoint = "http://keycloak:8080/realms/master/protocol/openid-connect/token",
        jwks_uri = "http://keycloak:8080/realms/master/protocol/openid-connect/certs",
        userinfo_endpoint = "http://keycloak:8080/realms/master/protocol/openid-connect/userinfo",
        revocation_endpoint = "http://keycloak:8080/realms/master/protocol/openid-connect/revoke",
        introspection_endpoint = "http://keycloak:8080/realms/master/protocol/openid-connect/token/introspect"
    },
    client_id = "couchdb-proxy",
    client_secret = "32scbZbgGNSaVOAAuZHgYeTjdQrkfwTh",
    scope = "openid couchdb",
    renew_access_token_on_expiry = true,
    access_token_expires_in = 60,
    access_token_expires_at = 5,
    accept_none_alg = false,
    accept_unsupported_alg = false,
    session_contents = {
        id_token = true,
        access_token = true,
        refresh_token = true
    }
}

local res, err = require("resty.openidc").authenticate(opts)

if err then
    ngx.status = 500
    ngx.say(err)
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

if res then
    ngx.req.set_header("Authorization", "Bearer " .. res.access_token)
end
