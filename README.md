OIDC Kubernetes Authentication with Keycloak
==================


### Create CA, Issuer and Keycloak Certificate

```sh
kubectl apply -f issuer.yml
kubectl apply -f certificate.yml
```


### Install Keycloak

see the README.me in the keycloak directory

### created a keycloak user on the ui
cafanwii
sec

### Configure API Server

```sh
k -n kube-system get po | grep kube-api
k -n kube-system describe po kube-apiserver-k8s-prod-master1
k -n keycloak get certificates
k -n keycloak get secret root-secret -o yaml
echo    | base64 -d
```

### echo the ca.crt value

```sh
echo  S0tLS1xxxxxxxxxxxxxo=  | base64 -d
```

-----BEGIN CERTIFICATE-----
MIIBazCCARKgAwIBAgIQPLqDPFP9XzCs7hNUde4ISjAKBggqhkjOPQQDAjAWMRQw
EgYDVQQDEwtrZXljbG9hay1jYTAeFw0yNDA2MTQwMDE0MDhaFw0yNDA5MTIwMDE0
MDhaMBYxFDASBgNVBAMTC2tleWNsb2FrLWNhMFkwEwYHKoZIzj0CAQYIKoZIzj0D
AQcDQgAE0IqYeHfY9BfbkdKYFiM6Z5zevgjUhU2L8qis+ivGvjp+rS5x3NKUpUHT
NUollT+HQe4ZX95xLVepWjQfpnn1VqNCMEAwDgYDVR0PAQH/BAQDAgKkMA8GA1Ud
EwEB/wQFMAMBAf8wHQYDVR0OBBYEFKl9h/pwl1jXlW3685QLyFU3Rao2MAoGCCqG
SM49BAMCA0cAMEQCIEBS6EgQODjLQqeKPe6yd/caSt5EPvZ9V0mjq65CbIItAiBe
sXZ/34mkeoXBdjaKyl3JV4cS37gMyN+QDmfsZ5sfjw==
-----END CERTIFICATE-----

```sh
# Create file with Keycloak CA certificate
vi /etc/ssl/certs/keycloak-ca.crt
# Edit kube-apiserver manifest
vi /etc/kubernetes/manifests/kube-apiserver.yaml

# Add below extra args to kube-apiserver command
- —-oidc-issuer-url=keycloak.re-lux.club/auth/realms/kubernetes  
- —-oidc-client-id-kubernetes
- —-oidc-username-claim=email
- —-oidc-groups-claim=groups
- —-oidc-ca-file=/etc/ssl/certs/kevcloak-ca.crt
```

mv kubelogin kubectl-oidc_login

### Create OIDC User

```sh
kubectl config set-credentials cafanwii\
--exec-api-version=client.authentication.k8s.io/v1beta1 \
--exec-command=kubectl \
--exec-arg=oidc-login \
--exec-arg=get-token \
--exec-arg=--oidc-issuer-url=https://keycloak.re-lux.club/realms/kubernetes \
--exec-arg=--oidc-client-id=kubernetes \
--exec-arg=--oidc-extra-scope="groups email openid" \
--exec-arg=--oidc-client-secret=MYk9RMLnUVnmdealpHOI2aWaIcScKGnW \
--exec-arg=--insecure-skip-tls-verify
```

### get current context
kubectl config get-clusters
kubectl config get-users

### Set OIDC User as default for current context

```sh
kubectl config set-context k8s-prod-master1 --cluster=k8s-prod-master1 --user=oidc-admin
```

### Create ClusterRoleBinding

```sh
kubectl apply -f user-cluster-role-binding.yml
```

https://vault.sosotechnologies.com/ui/vault/auth/oidc/oidc/callback
------------------

<!-- ### Enable Audit Logs for API Server

```sh
# Create policy directory and policy file.
mkdir /etc/kubernetes/audit-policy

cat <<EOF > /etc/kubernetes/audit-policy/pods-audit-policy-yaml
apiVersion: audit.k8s.io/v1
kind: Policy rules:
   # Log pod changes at RequestResponse level
   - level: RequestResponse 
   resources:
      - group:
         resources: ["pods"]
EOF
# Edit kube-apiserver manifest
vi /etc/kubernetes/manifests/kube-apiserver.yaml

# Add below volumes configuration
volumes: 
- hostPath:
    path: /etc/kubernetes/audit-policy 
    type: DirectoryOrCreate
  name: audit-policy 
- hostPath:
    path: /var/log/audit 
    type: DirectoryOrCreate
  name: audit-logs

# Add below volume mount configuration

volumeMounts:
- mountPath: /etc/kubernetes/audit-policy 
  name: audit-policy
- mountPath: /var/log/audit 
  name: audit-logs

# Add below extra args to kube-apiserver command

- --audit-log-path=/var/log/audit/kube-apiserver-audit.log
- --audit-policy-file=/etc/kubernetes/audit-policy/pods-audit-policy-yaml

```

## other ref
### install Nginx-ingress
https://github.com/kubernetes/ingress-nginx

## prerequisites
- install any webapp service, In my example I have a keycloak service already
- save the ingress load balancer ip as a wildcard A record: A   |  *  | 10.0.0.19

```sh
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm search repo ingress-nginx --versions

kubectl create namespace ingress-nginx


CHART_VERSION="4.10.1"
APP_VERSION="1.10.1"

helm template ingress-nginx ingress-nginx  \
--repo https://kubernetes.github.io/ingress-nginx \
--version ${CHART_VERSION} \
--namespace ingress-nginx \
> ./nginx-ingress.${APP_VERSION}.yaml

k apply -f ./nginx-ingress.${APP_VERSION}.yaml
kubectl get pods -n ingress-nginx
kubectl -n ingress-nginx get svc 
kubectl get services -o wide -w --namespace ingress-nginx
```

### install certmanager
## NOTE TO SELF
All TLS are installed on mainframe server

### Install certbot
sudo apt install certbot
sudo certbot certificates

## Install cert manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.11.0/cert-manager.yaml
kubectl get pods --namespace cert-manager
kubectl get clusterissuer letsencrypt-prod -n cert-manager



```sh
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: macfenty@gmail.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
```

```sh
kubectl get clusterissuer letsencrypt-prod -n cert-manager
```

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: keycloak-tls
  namespace: keycloak
spec:
  dnsNames:
  - "*.re-lux.club"
  issuerRef:
    kind: ClusterIssuer
    name: letsencrypt-prod
  secretName: keycloak-tls
```

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: keycloak-ingress
  namespace: keycloak
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - "*.re-lux.club"
    secretName: keycloak-tls
  rules:
  - host: keycloak.re-lux.club
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: keycloak-http
            port:
              number: 80
```

kubectl describe certificate keycloak-tls -n keycloak
kubectl get secret -n keycloak
kubectl logs -l app=cert-manager -n cert-manager
dig *.re-lux.club
dig keycloakedd.re-lux.club
dig TXT _acme-challenge.re-lux.club
dig A 10.0.0.
 -->


sudo certbot certonly --manual -d *.globalwealthorder.com --agree-tos --manual-public-ip-logging-ok --preferred-challenges dns-01 --server https://acme-v02.api.letsencrypt.org/directory --email=macfenty@gmail.com --rsa-key-size 4096