##### Todo

- [ ] Resolve the issue with the `OAUTH2_PROXY_INSECURE_OIDC_SKIP_ISSUER_VERIFICATION` environment variable. 
- [ ] Configure keycloak clients using configuration file instead of manual configuration.
- [ ] Logout from the CouchDB GUI is not working properly as the user is still logged in after logout.

I think I should consider here three different scenarios for the authentication:

1. Authentication to Fauxton (CouchDB GUI)
2. Authentication to CouchDB Standalone Application
3. Shell authentication with web browser

### Web Browser Authentication

TBD

### Shell Authentication

```shell
curl -s 'https://auth.oblivio.localhost/realms/master/.well-known/openid-configuration' | jq -r '.authorization_endpoint'
```
