resource "vault_auth_backend" "userpass" {
  type = "userpass"
}

resource "vault_generic_endpoint" "sosouser" {
  depends_on           = [vault_auth_backend.userpass]
  path                 = "auth/userpass/users/sosotechusers"
  ignore_absent_fields = true

  data_json = <<EOT
{
  "policies": ["admin","sosotech-users"],
  "password": "changeme"
}
EOT
}