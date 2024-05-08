resource "vault_mount" "kv-v2" {
  path                      = "kv-v2"
  type                      = "kv-v2"
}

resource "vault_mount" "transit" {
  path                      = "soso-transit"
  type                      = "transit"
  description               = "sosotech vault mount"
  default_lease_ttl_seconds = 3600
  max_lease_ttl_seconds     = 86400
}

resource "vault_transit_secret_backend_key" "key" {
  depends_on = [vault_mount.transit]
  backend    = vault_mount.transit.path
  name       = "sosotechkey"
}
