https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/identity_oidc

https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/identity_oidc

## 1. Set up a userpass authentication backend
- The type of authentication backend being configured is userpass, which is a username/password authentication method.
- code sets up a Vault and creates a user (sosotechusers) within that backend with the specified policies and password.
- The path parameter specifies the path at which the user will be created within the userpass authentication backend.

## 2. Create 2 different vault_mount 
### key-value version 2 (kv-v2):
This resource configures a secrets engine mount  (kv-v2), type of secrets engine being configured is kv-v2.
### vault_mount for Transit:
- This resource configures another secrets engine mount, this time for the Transit secrets engine.
- The Transit secrets engine is used for cryptographic operations such as encryption and decryption of data.
- The path parameter specifies the path where the Transit secrets engine will be mounted within Vault is called: soso-transit.
- The type parameter specifies the type of secrets engine, which is transit.
- The name parameter specifies the name of the encryption key, in this case, it's set to sosotechkey.

## 3. Create 2 different policies from files
- Create a folder /policy and add defined policies
- copy hcl files in the blocks of policy 
### vault_policy named "policy1":
This resource defines a policy named "sosotransient-policy1" .
The policy parameter specifies the content of the policy file located at "policy/sosopolicy-1.hcl" using the file function.
### vault_policy named "policy2":
This resource defines a policy named "sosotransient-policy2" .
The policy parameter specifies the content of the policy file located at "policy/sosopolicy-2.hcl" using the file function.






