
path "auth/*" {
    capabilities = ["read", "sudo", "create", "update", "delete", "list"]
}

path "sys/auth*" {
    capabilities = ["create", "update", "delete", "sudo"]
}

path "sys/auth" {
    capabilities = ["read"]
}