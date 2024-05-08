# Configure Vault as a certificate manager in Kubernetes with Helm

```sh
git clone https://github.com/hashicorp-education/learn-vault-external-kubernetes.git
cd learn-vault-external-kubernetes
kubectl -n vault exec -it vault-0 -- /bin/sh
```

## Enable the PKI secrets engine at its default path.
```sh
vault secrets enable pki
vault secrets tune -max-lease-ttl=8760h pki
```

## Generate a self-signed certificate valid for 8760h.

```sh
vault write pki/root/generate/internal \
    common_name=cafanwi.com \
    ttl=8760h
```

## Configure the PKI secrets engine certificate issuing and certificate revocation list (CRL) endpoints to use the Vault service in the default namespace.

```sh
vault write pki/config/urls \
    issuing_certificates="https://vault.sosotechnologies.com//v1/pki/ca" \
    crl_distribution_points="https://vault.sosotechnologies.com//v1/pki/crl"
```

## Configure a role named example-dot-com that enables the creation of certificates cafanwi.com domain with any subdomains.

```sh
vault write pki/roles/example-dot-com \
    allowed_domains=cafanwi.com \
    allow_subdomains=true \
    max_ttl=72h
```

## Create a policy named pki that enables read access to the PKI secrets engine paths.

```sh
vault policy write pki - <<EOF
path "pki*"                        { capabilities = ["read", "list"] }
path "pki/sign/example-dot-com"    { capabilities = ["create", "update"] }
path "pki/issue/example-dot-com"   { capabilities = ["create"] }
EOF
```

# NEXT: Configure Kubernetes authentication

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
    server: https://vault.sosotechnologies.com
    path: pki/sign/example-dot-com
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
```

## Define a certificate named cafanwi-com.
```yaml
cat > example-com-cert.yaml <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: cafanwi-com
  namespace: default
spec:
  secretName: example-com-tls
  issuerRef:
    name: vault-issuer
  commonName: www.cafanwi.com
  dnsNames:
  - www.cafanwi.com
EOF
```

## apply the file
```sh
kubectl apply --filename example-com-cert.yaml
kubectl describe certificate.cert-manager cafanwi-com
```