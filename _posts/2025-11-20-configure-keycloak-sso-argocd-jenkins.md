---
layout: post
title: How to configure KeyCloak SSO with argocd, jenkins
date: 2025-11-20 18:46:28 +09:00
tags:
  - kubernetes
  - keycloak
  - argocd
  - jenkins
categories:
  - kubernetes
---
# ArgoCD Keycloak 연동하기

## Prerequisite
- kubectl

## kind cluster 배포하기

```bash
kind create cluster --config cluster.yaml
Creating cluster "myk8s" ...
 ✓ Ensuring node image (kindest/node:v1.32.8) 🖼
 ✓ Preparing nodes 📦  
 ✓ Writing configuration 📜 
 ✓ Starting control-plane 🕹️ 
 ✓ Installing CNI 🔌 
 ✓ Installing StorageClass 💾 
Set kubectl context to "kind-myk8s"
You can now use your cluster with:

kubectl cluster-info --context kind-myk8s

Not sure what to do next? 😅  Check out https://kind.sigs.k8s.io/docs/user/quick-start/

# cluster-info
kubectl cluster-info --context kind-myk8s
Kubernetes control plane is running at https://127.0.0.1:53194
CoreDNS is running at https://127.0.0.1:53194/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```
```bash
# kind k8s 배포
kind create cluster --name myk8s --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: myk8s
nodes:
  - role: control-plane
    image: kindest/node:v1.32.8
    labels:
      ingress-controller: true
    extraPortMappings:
      - containerPort: 80
        hostPort: 80
      - containerPort: 443
        hostPort: 443
      - containerPort: 30000
        hostPort: 30000
      - containerPort: 30001
        hostPort: 30001
      - containerPort: 30002
        hostPort: 30002
      - containerPort: 30003
        hostPort: 30003
      - containerPort: 30004
        hostPort: 30004
      - containerPort: 30005
        hostPort: 30005
    extraMounts:
      - hostPath: /private/var/persist/jenkins
        containerPath: /private/var/persist/jenkins
EOF

# 노드 라벨 확인
kubectl get nodes myk8s-control-plane -o jsonpath={.metadata.labels} | jq
{
  "ingress-controller": "true",
  "kubernetes.io/hostname": "myk8s-control-plane",
}
```

## ingress-nginx 배포하기
* https://kind.sigs.k8s.io/docs/user/ingress

```bash
curl -O https://kind.sigs.k8s.io/examples/ingress/deploy-ingress-nginx.yaml
```

```bash
# --enable-ssl-passthrough 옵션을 ingress-nginx-controller deployment 에 추가해야함.
--- a/kubernetes/deploy-ingress-nginx.yaml
+++ b/kubernetes/deploy-ingress-nginx.yaml
@@ -431,6 +431,7 @@ spec:
         - --validating-webhook-key=/usr/local/certificates/key
         - --watch-ingress-without-class=true
         - --publish-status-address=localhost
+        - --enable-ssl-passthrough
         env:
         - name: POD_NAME
           valueFrom:

# 배포하기
kubectl apply -f deploy-ingress-nginx.yaml

# 배포 확인
kubectl get pods -n ingress-nginx
```


## Jenkins 배포 하기

```bash
kubectl create ns cicd-jenkins

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: jenkins-pv
  namespace: cicd-jenkins
spec:
  capacity:
    storage: 10Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: cicd-local-storage
  hostPath:
    path: /private/var/persist/jenkins

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: jenkins-pvc
  namespace: cicd-jenkins
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: cicd-local-storage
EOF
```

[jenkins-5.8.104](https://github.com/youngseokyoon/jenkinsci-helm-charts)
```
git clone git@github.com:youngseokyoon/jenkinsci-helm-charts.git -b dev

cd jenkinsci-helm-charts

helm install cicd-jenkins \
  -n cicd-jenkins \
  -f charts/jenkins/jenkins-cicd-values.yaml \
  charts/jenkins
```

```bash
echo "127.0.0.1 jenkins.cicd.com" | sudo tee -a /etc/hosts

open https://jenkins.cicd.com/
# jenkins-5.8.104-values.yaml에 선언되어있는 값으로 로그인.
# admin / admin
```

## Argo CD 배포 하기
```bash
kubectl create ns argocd
helm install argocd argo/argo-cd --version 9.1.0 -f argocd-keycloak-vaules.yaml -n argocd
```

```bash
echo "127.0.0.1 argocd.cicd.com" | sudo tee -a /etc/hosts

open https://argocd.cicd.com/

kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d ;echo
Wil-wjezvnallast
```

### Argo CD CLI 설치
```bash
ARGOPW=Wil-wjezvnallast

# argocd 서버 cli 로그인 : argocd cli 설치 필요
argocd login argocd.cicd.com --insecure --username admin --password $ARGOPW
'admin:login' logged in successfully
Context 'argocd.cicd.com' updated

# 확인
argocd cluster list
argocd proj list
argocd account list

# admin 계정 암호 변경 : argo12345
argocd account update-password --current-password $ARGOPW --new-password argo12345
Password updated
Context 'argocd.cicd.com' updated
```

## Keycloak
* 8090 포트로 Keycloak 배포

### 배포하기
```bash
kubectl create ns keycloak
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: keycloak
  namespace: keycloak
  labels:
    app: keycloak
spec:
  replicas: 1
  selector:
    matchLabels:
      app: keycloak
  template:
    metadata:
      labels:
        app: keycloak
    spec:
      containers:
        - name: keycloak
          image: quay.io/keycloak/keycloak:26.4.0
          args:
            - "start-dev"
            - "--http-port=8090"
          env:
            - name: KC_PROXY
              value: "edge"
            - name: KC_HOSTNAME
              value: "keycloak.cicd.com"
            - name: KC_BOOTSTRAP_ADMIN_USERNAME
              value: admin
            - name: KC_BOOTSTRAP_ADMIN_PASSWORD
              value: admin
          ports:
            - containerPort: 8090
---
apiVersion: v1
kind: Service
metadata:
  name: keycloak
  namespace: keycloak
spec:
  selector:
    app: keycloak
  ports:
    - name: http
      port: 80
      targetPort: 8090
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: keycloak
  namespace: keycloak
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
    nginx.ingress.kubernetes.io/ssl-redirect: "false" 
    nginx.ingress.kubernetes.io/use-forwarded-headers: "true"
spec:
  ingressClassName: nginx
  rules:
    - host: keycloak.cicd.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: keycloak
                port:
                  number: 80
EOF
```

```bash
echo "127.0.0.1 keycloak.cicd.com" | sudo tee -a /etc/hosts

open https://keycloak.cicd.com/
```

## coreDNS 설정
```bash
k get svc -A | grep -e argocd-server -e cicd-jenkins -e keycloak
argocd          argocd-server                        ClusterIP      10.96.147.229   <none>        80/TCP,443/TCP               165m
cicd-jenkins    cicd-jenkins                         ClusterIP      10.96.188.33    <none>        8080/TCP                     116m
cicd-jenkins    cicd-jenkins-agent                   ClusterIP      10.96.170.226   <none>        50000/TCP                    116m
keycloak        keycloak                             ClusterIP      10.96.253.101   <none>        80/TCP                       31m
```

argocd: 10.96.147.229
jenkins: 10.96.188.33
keycloak: 10.96.253.101

```bash
kubectl edit cm -n kube-system coredns

.:53 {
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
           ttl 30
        }
        hosts {
           10.96.188.33 jenkins.cicd.com
           10.96.147.229 argocd.cicd.com
           10.96.253.101 keycloak.cicd.com
           fallthrough
        }
        reload # cm 설정 변경 시 자동으로 reload 적용됨
```


## 연동하기
- Jenkins, ArgoCD 와 Keycloak 을 연동


eqnPQ1gp9mtEokZMocWYnvzTl8hGV1E9

- ArgoCD 와 Keycloak 을 OIDC(OpenID Connect) 방식으로 연동
- ArgoCD 에서 Keycloak 을 인증 제공자(IdP)로 설정
- Keycloak 에서 ArgoCD 를 클라이언트로 설정

https://keycloak.cicd.com/ 접속 후 admin/admin 으로 로그인


- 좌측 User 메뉴 -> Add User -> Username: argocd-user -> Create
- Credentials 메뉴 -> Set password: argocd-pass, Temporary: OFF -> Save, Save password
- Clients 메뉴 -> Create client
    - -> General Settings
        - Client type: OpenId Connect
        - Client ID: argocd-cicd
        - Name: argocd-cicd-client
    - -> Capability config
        - Client Authentication: ON
        - Authentication flow: Standard Flow
    - -> Login Settings
        - Root URL: https://argocd.cicd.com
        - Home URL: /applications
        - Valid redirect URLs : https://argocd.cicd.com/auth/callback
        - Valid post logout redirect URIs : https://argocd.cicd.com/applications
        - Web origins: +

    - Credentials 탭 -> Client Secret 복사
        - 해당 값은 ArgoCD OIDC 설정 시 필요함.
      ```
      Vb424xkU9aM42oCHYr7lg6LowtPLjVP8
      ```

## 참고 링크
- [keycloak 공식 문서](https://www.keycloak.org/)
- [kind ingress 문서](https://kind.sigs.k8s.io/docs/user/ingress)

