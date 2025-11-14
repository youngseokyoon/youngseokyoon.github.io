---
layout: post
title: How to configure kubernetes cluster with k3s
date: 2025-10-14
tags:
  - kubernetes
  - k3s
  - ubuntu
  - argocd
categories:
  - kubernetes
---
Ubuntu 24.04 환경에서 k3s k8s 클러스터에 ArgoCD 를 helm charts 를 사용하여 설치

# Prerequisites
- [k3s cluster](https://k3s.io/)

Multipass 환경에서 K3s 및 ArgoCD를 이용한 도메인 접속이 가능하도록 구성한 문서

## [Traefik?](https://github.com/traefik/traefik)
컨테이너나 Kubernetes 환경에서 동작하는 Reverse Proxy, 인그레스 컨트롤러(Ingress Controller) 임.

Traefik is a modern HTTP reverse proxy and load balancer

## argocd 재배포 하기
```argocd-k3s.yaml
dex:
  enabled: false

global:
  nodeSelector:
    app: argocd

configs:
  cm:
    server.insecure: true

  params:
    server.insecure: true

server:
  service:
    type: ClusterIP

  insecure: true
  ingress:
    enabled: false
```

- ClusterIP로 설정
- 기본적으로 생성하는 Ingress(argocd-server ingress) 사용하지 않음.
```
server:
  ingress:
    enabled: false
```

http 사용을 위한 옵션 추가해야함. 이 옵션은 ConfigMap 존재 하고, 아래 처럼 설정을 해줘야함

> kubectl -n argocd get cm argocd-cm -o yaml

```
configs:
  cm:
    server.insecure: true

  params:
    server.insecure: true
```

```
helm install argocd argo/argo-cd -n argocd -f argocd-k3s.yaml

helm upgrade argocd argo/argo-cd -n argocd -f argocd-k3s.yaml
```

## argocd-ingress 등록하기
```argocd-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-ingress
  namespace: argocd
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    traefik.ingress.kubernetes.io/router.tls: "true"
    traefik.ingress.kubernetes.io/force-ssl-redirect: "false"
    traefik.ingress.kubernetes.io/forwarded-headers-insecure: "true"

spec:
  ingressClassName: traefik
  tls:
    - hosts:
        - argocd.cicd.com
      secretName: argocd-tls
  rules:
    - host: argocd.cicd.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: argocd-server
                port:
                  number: 80
```

argocd-server 에 동작하도록 설정을 해야 하기에 아래 처럼 backend 등록이 필요함.

```
  rules:
    - host: argocd.cicd.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: argocd-server
                port:
                  number: 80
```

# 참고 링크

- https://docs.k3s.io/networking/networking-services
- https://github.com/traefik/traefik
- https://doc.traefik.io/