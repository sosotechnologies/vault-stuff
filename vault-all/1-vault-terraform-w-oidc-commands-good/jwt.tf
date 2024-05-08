resource "vault_identity_oidc_key" "key" {
  name               = "keycloak"
  allowed_client_ids = ["*"]
  rotation_period    = 3600
  verification_ttl   = 3600
}

resource "vault_identity_oidc_client" "app" {
  name          = "vault"
  key           = vault_identity_oidc_key.key.name
  redirect_uris = [
    "https://vault.sosotechnologies.com/ui/vault/auth/oidc/oidc/callback",
    "https://vault.sosotechnologies.com/oidc/callback"
  ]
#   id_token_ttl     = 2400
#   access_token_ttl = 7200
}

resource "vault_identity_oidc_provider" "provider" {
 name = "provider"
 allowed_client_ids = [
  vault_identity_oidc_client.app.client_id
 ]
}

data "vault_identity_oidc_openid_config" "config" {
  name = vault_identity_oidc_provider.provider.name
}