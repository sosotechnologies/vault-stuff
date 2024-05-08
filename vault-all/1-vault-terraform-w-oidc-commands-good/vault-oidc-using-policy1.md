## Login to the vault server and enable the OIDC auth method
```sh
VAULT_LOGIN=hvs.
vault login $VAULT_LOGIN
export VAULT_ADDR=https://vault.sosotechnologies.com
vault auth enable oidc
```

## Apply the following variables
```sh
export OIDC_CLIENT_ID=vault
export OIDC_CLIENT_SECRET=NsqbLSxa85Q
export ALLOWED_REDIRECT_URI_1=https://vault.sosotechnologies.com/ui/vault/auth/oidc/oidc/callback
export ALLOWED_REDIRECT_URI_2=https://vault.sosotechnologies.com/oidc/callback
export OIDC_DISCOVERY_URL=https://keycloakdev.sosotechnologies.com/auth/realms/sosotechdev
```

## view it

```sh
vault policy list
```

## OIDC RELATED: create an OIDC role with the reader policy that also has a groups claim that can map Keycloak groups to Vault. Note that there does not seem to be any way to create or view OIDC roles from the Web UI.

```sh
vault write auth/oidc/role/sosotransient-policy1 \
  bound_audiences="$OIDC_CLIENT_ID" \
  allowed_redirect_uris="$ALLOWED_REDIRECT_URI_1" \
  allowed_redirect_uris="$ALLOWED_REDIRECT_URI_2" \
  user_claim="sub" \
  policies="sosotransient-policy1" \
  role_type="oidc" \
  groups_claim="groups"
```

## view it

```sh
vault list auth/oidc/role
vault read -format=json auth/oidc/role/reader
```

## configure the OIDC auth method
```sh
vault write auth/oidc/config \
  oidc_discovery_url="$OIDC_DISCOVERY_URL" \
  oidc_client_id="$OIDC_CLIENT_ID" \
  oidc_client_secret="$OIDC_CLIENT_SECRET" \
  default_role=sosotransient-policy1
```

##
cafanwii
Depay200$
