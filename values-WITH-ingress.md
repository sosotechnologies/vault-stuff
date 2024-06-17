fullnameOverride: ""
nameOverride: ""
replicas: 1

image:
  repository: quay.io/keycloak/keycloak
  tag: ""
  pullPolicy: IfNotPresent

imagePullSecrets: []
hostAliases: []
enableServiceLinks: true
podManagementPolicy: Parallel
updateStrategy: RollingUpdate
restartPolicy: Always

serviceAccount:
  create: true
  name: ""
  annotations: {}
  labels: {}
  imagePullSecrets: []
rbac:
  create: false
  rules: []
podSecurityContext:
  fsGroup: 1000
securityContext:
  runAsUser: 1000
  runAsNonRoot: true
extraInitContainers: ""
skipInitContainers: false
extraContainers: ""
lifecycleHooks: |

terminationGracePeriodSeconds: 60
clusterDomain: cluster.local
command: []
args: []
extraEnv: |
  - name: KEYCLOAK_USER
    value: collins
  - name: KEYCLOAK_PASSWORD
    value: secret
  - name: DB_VENDOR
    value: postgres
  - name: DB_ADDR
    value: 10.0.0.36
  - name: DB_PORT
    value: "5432"
  - name: DB_DATABASE
    value: keycloakprod
  - name: DB_USER
    value: cafanwiiuser
  - name: DB_PASSWORD
    value: Depay20$
  - name: KC_HOSTNAME
    value: keycloak.re-lux.club
  - name: KC_PROXY
    value: passthrough
  - name: KC_HOSTNAME_STRICT_HTTPS
    value: "true"
  - name: KC_HOSTNAME_STRICT
    value: "true"
  - name: KC_HTTP_ENABLED
    value: "true"   
  - name: PROXY_ADDRESS_FORWARDING
    value: "true"
  - name: KC_HTTP_RELATIVE_PATH
    value: /auth

extraEnvFrom: ""
priorityClassName: ""
affinity: |
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchLabels:
            {{- include "keycloak.selectorLabels" . | nindent 10 }}
          matchExpressions:
            - key: app.kubernetes.io/component
              operator: NotIn
              values:
                - test
        topologyKey: kubernetes.io/hostname
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchLabels:
              {{- include "keycloak.selectorLabels" . | nindent 12 }}
            matchExpressions:
              - key: app.kubernetes.io/component
                operator: NotIn
                values:
                  - test
          topologyKey: failure-domain.beta.kubernetes.io/zone

topologySpreadConstraints:
nodeSelector: {}
tolerations: []
podLabels: {}
podAnnotations: {}
livenessProbe: |
  httpGet:
    path: /auth/
    port: http
  initialDelaySeconds: 0
  timeoutSeconds: 5
readinessProbe: |
  httpGet:
    path: /auth/realms/master
    port: http
  initialDelaySeconds: 30
  timeoutSeconds: 1
startupProbe: |
  httpGet:
    path: /auth/
    port: http
  initialDelaySeconds: 30
  timeoutSeconds: 1
  failureThreshold: 60
  periodSeconds: 5
resources: {}

startupScripts:
  keycloak.cli: |
    {{- .Files.Get "scripts/keycloak.cli" }}
extraVolumes: ""
extraVolumeMounts: ""
extraPorts: []
podDisruptionBudget: {}
statefulsetAnnotations: {}
statefulsetLabels: {}
secrets: {}

service:
  annotations: {}
  labels: {}
  type: ClusterIP
  loadBalancerIP: ""
  httpPort: 80
  httpNodePort: null
  httpsPort: 8443
  httpsNodePort: null
  httpManagementPort: 9990
  httpManagementNodePort: null
  extraPorts: []
  loadBalancerSourceRanges: []
  externalTrafficPolicy: "Cluster"
  sessionAffinity: ""
  sessionAffinityConfig: {}


ingress:
  enabled: true
  ingressClassName: "nginx" 
  servicePort: https
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: HTTPS
  labels: {}
  rules:
    -
      host: keycloak.re-lux.club
      paths:
        - path: /
          pathType: Prefix
  tls:
    - hosts:
        - keycloak.re-lux.club
      secretName: keycloak-tls

  console:
    enabled: false
    ingressClassName: ""
    annotations: {}
    rules:
      -
        host: '{{ .Release.Name }}.keycloak.re-lux.club'
        paths:
          - path: /auth/admin/
            pathType: Prefix

networkPolicy:
  enabled: false
  labels: {}
  extraFrom: []

route:
  enabled: false
  path: /
  annotations: {}
  labels: {}
  host: ""
  tls:
    enabled: true
    insecureEdgeTerminationPolicy: Redirect
    termination: edge

pgchecker:
  image:
    repository: docker.io/busybox
    tag: 1.32
    pullPolicy: IfNotPresent
  securityContext:
    allowPrivilegeEscalation: false
    runAsUser: 1000
    runAsGroup: 1000
    runAsNonRoot: true
  resources:
    requests:
      cpu: "20m"
      memory: "32Mi"
    limits:
      cpu: "20m"
      memory: "32Mi"

postgresql:
  enabled: false
  postgresqlUsername: cafanwiiuser
  postgresqlPassword: Depay20$
  postgresqlDatabase: keycloakproduction
  networkPolicy:
    enabled: false

serviceMonitor:
  enabled: false
  namespace: ""
  namespaceSelector: {}
  annotations: {}
  labels: {}
  interval: 10s
  scrapeTimeout: 10s
  path: /metrics
  port: http-management

extraServiceMonitor:
  enabled: false
  namespace: ""
  namespaceSelector: {}
  annotations: {}
  labels: {}
  interval: 10s
  scrapeTimeout: 10s
  path: /auth/realms/master/metrics
  port: http

prometheusRule:
  enabled: false
  annotations: {}
  labels: {}
  rules: []

autoscaling:
  enabled: false
  labels: {}
  minReplicas: 3
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Pods
          value: 1
          periodSeconds: 300

test:
  enabled: false
  image:
    repository: docker.io/unguiculus/docker-python3-phantomjs-selenium
    tag: v1
    pullPolicy: IfNotPresent
  podSecurityContext:
    fsGroup: 1000
  securityContext:
    runAsUser: 1000
    runAsNonRoot: true
  deletionPolicy: before-hook-creation
