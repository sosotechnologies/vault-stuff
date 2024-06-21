## Step 1: Prepare Local Storage Directories on Nodes
```sh
ssh cafanwii@staging-master
sudo mkdir -p /mnt/disks/vol1
sudo mkdir -p /mnt/disks/vol2
sudo mkdir -p /mnt/disks/vol3
sudo chown cafanwii:cafanwii /mnt
sudo chown cafanwii:cafanwii /mnt/
sudo chown cafanwii:cafanwii /mnt/*
sudo chown cafanwii:cafanwii /mnt/disks
sudo chown cafanwii:cafanwii /mnt/disks/
sudo chown cafanwii:cafanwii /mnt/disks/*
sudo chown cafanwii:cafanwii /mnt/disks/vol1
sudo chown cafanwii:cafanwii /mnt/disks/vol1/
sudo chown cafanwii:cafanwii /mnt/disks/vol2
sudo chown cafanwii:cafanwii /mnt/disks/vol2/
sudo chown cafanwii:cafanwii /mnt/disks/vol3
sudo chown cafanwii:cafanwii /mnt/disks/vol3/

# Repeat the above steps for staging-worker-1 and staging-worker-2
```

## Step 2: Create a StorageClass for Local Storage
Create a StorageClass that uses local storage.

```sh
kubectl apply -f 1-storage-class.yaml
```

## Step 3: Create Persistent Volume Manifests
Create Persistent Volumes (PVs) for each directory created on the nodes.

```sh
kubectl apply -f 2-pv.yaml
kubectl get pv
```

## Step 4: insytall vault with the  pv

```sh
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
helm pull hashicorp/vault --untar=true
kubectl create ns vault

helm -n vault install vault hashicorp/vault --set "injector.enabled=false" --set "server.dataStorage.enabled=true" --set "server.dataStorage.size=10Gi" --set "server.dataStorage.storageClass=local-storage"
```
#################################
# Configure Vault as a certificate manager in Kubernetes with Helm
[Link:](https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-cert-manager)
[Not related, but good resource](https://cert-manager.io/docs/configuration/vault/)

## For local storage - in my case I'm using Local-storage
I have already created SC and PV... so I will apply vault pvc
Refer to the directory  local-storage-all-3-nodes if using local-storage 

## Install vault
```sh
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
helm pull hashicorp/vault --untar=true
kubectl create ns vault

helm -n vault install vault hashicorp/vault --set "injector.enabled=false" --set "server.dataStorage.enabled=true" --set "server.dataStorage.size=10Gi" --set "server.dataStorage.storageClass=local-storage"

kubectl -n vault get pods
```

##  start unealing vault 

```sh
kubectl -n vault exec vault-0 -- vault operator init -key-shares=1 -key-threshold=1 \
      -format=json > init-keys.json
```

```sh
cat init-keys.json | jq -r ".unseal_keys_b64[]" 

VAULT_UNSEAL_KEY=$(cat init-keys.json | jq -r ".unseal_keys_b64[]")

kubectl -n vault exec vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY

kubectl -n vault get pods
```

## expose the service to LB
- I already have metallb installed for LoadBalancing

```sh
kubectl -n vault get svc 
kubectl patch svc vault -n vault -p '{"spec": {"type": "LoadBalancer"}}'
```

## get the token and sign in
```sh
cat init-keys.json | jq -r ".root_token"
```

## exec in the pod
```sh
kubectl -n vault exec -it vault-0 -- /bin/sh
```

## Run commands
```sh
export VAULT_ADDR=http://10.0.0.25:8200/
export VAULT_TOKEN=hvs.HTCURjssUCbasGTjtPyCYm2m
vault login $VAULT_TOKEN
```

## Enable the PKI secrets engine at its default path.
```sh
vault secrets enable pki
vault secrets tune -max-lease-ttl=8760h pki
```

## Generate a self-signed certificate valid for 8760h.
- This will create a Certificate, Issuer, key

```sh
vault write pki/root/generate/internal \
    common_name=angelpalms.com \
    ttl=8760h
```

## Configure the PKI secrets engine certificate issuing and certificate revocation list (CRL) endpoints to use the Vault service in the default namespace.

```sh
vault write pki/config/urls \
    issuing_certificates="http://10.0.0.25:8200/v1/pki/ca" \
    crl_distribution_points="http://10.0.0.25:8200/v1/pki/crl"
```

## Configure a role named angelpalms-role that enables the creation of certificates angelpalms.com domain with any subdomains.

```sh
vault write pki/roles/angelpalms-role \
    allowed_domains=angelpalms.com \
    allow_subdomains=true \
    max_ttl=72h
```

## Create a policy named pki that enables read access to the PKI secrets engine paths.

```sh
vault policy write pki - <<EOF
path "pki*"                        { capabilities = ["read", "list"] }
path "pki/sign/angelpalms-role"    { capabilities = ["create", "update"] }
path "pki/issue/angelpalms-role"   { capabilities = ["create"] }
EOF
```

##  exit the vault-0 pod.
```sh
exit
```

# NEXT: Configure Kubernetes authentication

## Re-exec in the pod 

```sh
kubectl -n vault exec -it vault-0 -- /bin/sh
```

## Enable the Kubernetes authentication method.

```sh
vault auth enable kubernetes
```

## Configure the Kubernetes authentication method to use location of the Kubernetes API.

```sh
vault write auth/kubernetes/config \
    kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443"
```

## Create a Kubernetes authentication role named issuer that binds the pki policy with a Kubernetes service account named issuer.
```sh
vault write auth/kubernetes/role/issuer \
    bound_service_account_names=issuer \
    bound_service_account_namespaces=default \
    policies=pki \
    ttl=20m
```

## Exit
```sh
exit
```

# Deploy Cert Manager - Jetstack's cert-manager

## Install Jetstack's cert-manager's version 1.12.3 resources.

```sh
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.14.5/cert-manager.crds.yaml
```

## Create a namespace named cert-manager to host the cert-manager.
```sh
kubectl create namespace cert-manager
```

## Add the jetstack chart repository.
```sh
helm repo add jetstack https://charts.jetstack.io
helm repo update
```

## Install the cert-manager chart version 0.11 in the cert-manager namespace.
```sh
helm install cert-manager \
    --namespace cert-manager \
    --version v1.14.5 \
  jetstack/cert-manager
```

## Het pods
```sh
kubectl get pods --namespace cert-manager
```

# Configure an issuer and generate a certificate

## Create a service account named [issuer] within the default namespace.
```sh
kubectl create serviceaccount issuer
```

## Create a secret definition.

```yaml
cat >> issuer-secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: issuer-token-lmzpj
  annotations:
    kubernetes.io/service-account.name: issuer
type: kubernetes.io/service-account-token
EOF
```

## Apply the secret
```sh
kubectl apply -f issuer-secret.yaml
kubectl get secrets
```

## Create a variable named ISSUER_SECRET_REF to capture the secret name.
```sh
ISSUER_SECRET_REF=$(kubectl get secrets --output=json | jq -r '.items[].metadata | select(.name|startswith("issuer-token-")).name')

echo $ISSUER_SECRET_REF
```

## Define an Issuer, named vault-issuer, that sets Vault as a certificate issuer.
```yaml
cat > vault-issuer.yaml <<EOF
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: vault-issuer
  namespace: default
spec:
  vault:
    server: http://10.0.0.25:8200
    path: pki/sign/angelpalms-role
    auth:
      kubernetes:
        mountPath: /v1/auth/kubernetes
        role: issuer
        secretRef:
          name: $ISSUER_SECRET_REF
          key: token
EOF
```


## apply the file
```sh
kubectl apply --filename vault-issuer.yaml
kubectl get issuer
```

## Define a certificate named angelpalms-com.
```yaml
cat > example-com-cert.yaml <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: angelpalms-com
  namespace: default
spec:
  secretName: example-com-tls
  issuerRef:
    name: vault-issuer
  commonName: www.angelpalms.com
  dnsNames:
  - www.angelpalms.com
EOF
```


## apply the file
```sh
kubectl apply --filename example-com-cert.yaml
kubectl describe certificate.cert-manager angelpalms-com
kubectl describe issuer vault-issuer -n default
kubectl logs -l app.kubernetes.io/name=cert-manager -n cert-manager
kubectl logs -l app.kubernetes.io/name=vault -n vault
```


