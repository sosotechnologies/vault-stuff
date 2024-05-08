resource "vault_policy" "policy1" {
  name   = "sosotransient-policy1"
  policy = file("policy/sosopolicy-1.hcl")
}

resource "vault_policy" "policy2" {
  name   = "sosotransient-policy2"
  policy = file("policy/sosopolicy-2.hcl")
}

output "policy_names" {
  value = [
    vault_policy.policy1.name,
    vault_policy.policy2.name
  ]
}



## OR use the method below if you dont want to use external policy files
# data "vault_policy_document" "sosopolicy" {
#   rule {
#     path         =  "soso-transit/encrypt/sosocrypto"
#     capabilities = ["create", "read", "update", "delete", "list"]

#   }

#   rule {
#     path         = "soso-transit/decrypt/sosocrypto"
#     capabilities = ["read", "sudo", "create", "update", "delete", "list"]
#   }

#   rule {
#     path         = "soso-transit/*"
#     capabilities = ["read", "sudo", "create", "update", "delete", "list"]
#   }
# }

# resource "vault_policy" "soso" {
#   name   = "sosotransient-policyreader"
#   policy = data.vault_policy_document.sosopolicy.hcl
# }

# resource "vault_auth_backend_userpass_auth_backend_user" "attach_policy1" {
#   backend     = vault_auth_backend.userpass.path
#   username    = "sosotechusers"
#   policies    = [vault_policy.policy1.name]
# }