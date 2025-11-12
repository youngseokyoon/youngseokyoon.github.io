#!/usr/bin/env bash
# language: bash

set -euo pipefail

TARGET_DIR="_posts"
START_DATE="2025-08-15"
COUNT=100

mkdir -p "$TARGET_DIR"

# DevOps tag pool (round-robin selection)
tags_pool=(
  devops kubernetes docker helm nginx istio linkerd "service-mesh"
  aws gcp azure terraform pulumi ansible chef puppet "argo-cd" jenkins
  "github-actions" "gitlab-ci" prometheus grafana loki tempo jaeger opentelemetry
  kafka rabbitmq consul etcd vault "cert-manager" traefik cilium calico flannel
  keda knative envoy haproxy kong keycloak ecr efs rds s3 cloudfront route53 ec2
  eks gke cloudrun cloudbuild cloudsql "cloud-storage" cloudwatch cloudtrail iam vpc
)

# Topics to compose titles
topics=(
  "Kubernetes Rollout Strategies" "Optimize Docker Images" "CI/CD Pipeline Setup"
  "Autoscaling Tuning" "Log Aggregation Basics" "Choosing Monitoring Metrics"
  "Service Mesh Overview" "Helm Chart Tips" "Network Policy Examples"
  "Container Security Checklist" "Build Cache Techniques" "Multi-stage Builds"
  "Secret Management" "Canary Deployment" "Blue-Green Deployment" "Health Check Design"
  "Resource Requests and Limits" "Local Dev Workflow" "Test Automation"
  "Rollback Planning" "Performance Profiling" "Database Migration"
  "Caching Strategies" "ConfigMap Usage" "Kubernetes Volumes" "Service Discovery"
  "Traffic Routing Basics" "TLS Certificate Management" "Vulnerability Scanning"
  "Dependency Hygiene" "Terraform State Management" "IaC Modularization"
  "Cost Optimization" "Policy-based Governance" "Rolling Update Tips"
  "Error Handling Patterns" "Pipeline Monitoring" "Incident Response"
  "Observability with OTel" "GitOps with Argo CD" "Cluster Autoscaler"
  "Ingress Best Practices" "API Gateway with Kong" "Tracing with Jaeger"
  "Metrics with Prometheus" "Dashboards with Grafana" "Security with Vault"
  "Sidecars and Envoy" "CNI with Cilium" "GitHub Actions CI" "GitLab CI"
  "KEDA Event-driven Autoscaling" "Knative Serverless" "Image Scanning"
  "Cert-Manager for TLS" "S3 Best Practices" "EKS Day-2 Ops" "GKE Day-2 Ops"
  "Cloud Run Basics" "Cloud Build Pipelines" "Cloud SQL Tips" "RDS Tips"
  "IAM Essentials" "VPC Design" "Route 53 DNS" "CloudFront CDN"
  "Traefik Ingress" "HAProxy Load Balancing" "Nginx Tuning" "Calico Network Policy"
  "Flannel Basics" "Consul Service Mesh" "etcd Operations" "Keycloak SSO"
  "Kafka Fundamentals" "RabbitMQ Patterns" "Loki Logs" "Tempo Traces"
  "OpenTelemetry Collector" "Pulumi with TS" "Ansible Playbooks" "Chef Cookbooks"
  "Puppet Modules" "Helm Library Charts" "Chart Testing" "Release Automation"
  "Blue/Green vs Canary" "Progressive Delivery" "Pre-commit Hooks"
  "Dependency Scanning" "Container Hardening" "SBOM and SLSA" "Backup and Restore"
  "Disaster Recovery" "Cost Reporting" "Policy as Code" "OPA/Gatekeeper"
  "FinOps Basics" "Incident Runbooks" "SRE Golden Signals" "Postmortems"
)

# -------------------------
# Helpers (Bash 3.2 compatible)
to_lc() {
  printf "%s" "$1" | tr '[:upper:]' '[:lower:]'
}

contains() {
  case "$1" in
    *"$2"*) return 0 ;;
    *) return 1 ;;
  esac
}

has_any_tag() {
  # args: t1 t2 t3 kw1 kw2 ...
  local t1="$1"; local t2="$2"; local t3="$3"; shift 3
  for kw in "$@"; do
    [ "$t1" = "$kw" ] && return 0
    [ "$t2" = "$kw" ] && return 0
    [ "$t3" = "$kw" ] && return 0
  done
  return 1
}

derive_primary_category() {
  # args: topic t1 t2 t3
  local topic="$1"; local t1="$2"; local t2="$3"; local t3="$4"
  local tlc; tlc="$(to_lc "$topic")"

  # Priority order
  if contains "$tlc" "kubernetes" || has_any_tag "$t1" "$t2" "$t3" kubernetes helm istio linkerd "service-mesh" cilium calico flannel keda knative "cert-manager" traefik nginx; then
    printf "%s" "Kubernetes"; return
  fi
  if contains "$tlc" "docker" || contains "$tlc" "container" || has_any_tag "$t1" "$t2" "$t3" docker; then
    printf "%s" "Containers"; return
  fi
  if contains "$tlc" "ci/cd" || contains "$tlc" "pipeline" || contains "$tlc" "gitops" || has_any_tag "$t1" "$t2" "$t3" "github-actions" "gitlab-ci" jenkins "argo-cd"; then
    printf "%s" "CI/CD"; return
  fi
  if contains "$tlc" "prometheus" || contains "$tlc" "grafana" || contains "$tlc" "loki" || contains "$tlc" "tempo" || contains "$tlc" "jaeger" || contains "$tlc" "opentelemetry" || contains "$tlc" "metrics" || contains "$tlc" "tracing" || contains "$tlc" "logs" || has_any_tag "$t1" "$t2" "$t3" prometheus grafana loki tempo jaeger opentelemetry; then
    printf "%s" "Observability"; return
  fi
  if contains "$tlc" "security" || contains "$tlc" "hardening" || contains "$tlc" "vulnerability" || contains "$tlc" "sbom" || contains "$tlc" "slsa" || contains "$tlc" "tls" || contains "$tlc" "certificate" || has_any_tag "$t1" "$t2" "$t3" vault keycloak "cert-manager"; then
    printf "%s" "Security"; return
  fi
  if contains "$tlc" "aws" || contains "$tlc" "gcp" || contains "$tlc" "azure" || contains "$tlc" "eks" || contains "$tlc" "gke" || contains "$tlc" "cloud run" || contains "$tlc" "cloud build" || contains "$tlc" "cloud sql" || contains "$tlc" "cloudfront" || contains "$tlc" "route 53" || contains "$tlc" "ec2" || contains "$tlc" "iam" || contains "$tlc" "vpc" || has_any_tag "$t1" "$t2" "$t3" aws gcp azure eks gke cloudrun cloudbuild cloudsql ecr efs rds s3 cloudfront route53 ec2 iam vpc cloudwatch cloudtrail; then
    printf "%s" "Cloud"; return
  fi
  if contains "$tlc" "network" || contains "$tlc" "ingress" || contains "$tlc" "routing" || contains "$tlc" "gateway" || has_any_tag "$t1" "$t2" "$t3" envoy haproxy kong traefik nginx "service-mesh"; then
    printf "%s" "Networking"; return
  fi
  if contains "$tlc" "kafka" || contains "$tlc" "rabbitmq" || has_any_tag "$t1" "$t2" "$t3" kafka rabbitmq; then
    printf "%s" "Messaging"; return
  fi
  if contains "$tlc" "terraform" || contains "$tlc" "pulumi" || contains "$tlc" "ansible" || contains "$tlc" "chef" || contains "$tlc" "puppet" || contains "$tlc" "iac" || has_any_tag "$t1" "$t2" "$t3" terraform pulumi ansible chef puppet; then
    printf "%s" "IaC"; return
  fi
  if contains "$tlc" "database" || contains "$tlc" "migration" || has_any_tag "$t1" "$t2" "$t3" etcd rds cloudsql; then
    printf "%s" "Databases"; return
  fi
  if contains "$tlc" "s3" || contains "$tlc" "efs" || has_any_tag "$t1" "$t2" "$t3" s3 efs; then
    printf "%s" "Storage"; return
  fi
  if contains "$tlc" "incident" || contains "$tlc" "runbook" || contains "$tlc" "postmortem" || contains "$tlc" "golden signals" || contains "$tlc" "disaster recovery" || contains "$tlc" "backup" || contains "$tlc" "finops" || contains "$tlc" "governance" || contains "$tlc" "opa" || contains "$tlc" "gatekeeper"; then
    printf "%s" "SRE"; return
  fi

  printf "%s" "DevOps"
}

# Safe ASCII slug
make_slug() {
  printf "%s" "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g'
}

# Ensure filename uniqueness by suffixing -2, -3, ...
next_available_filename() {
  local path="$1"
  if [ ! -e "$path" ]; then
    printf "%s" "$path"
    return
  fi
  local base="${path%.md}"
  local n=2
  local candidate
  while :; do
    candidate="${base}-${n}.md"
    [ ! -e "$candidate" ] && { printf "%s" "$candidate"; return; }
    n=$((n+1))
  done
}

echo "Generating $COUNT posts into '$TARGET_DIR' starting at $START_DATE ..."

n_tags=${#tags_pool[@]}
n_topics=${#topics[@]}

for ((i=0; i<COUNT; i++)); do
  # yyyy-mm-dd per post
  date=$(ruby -e "require 'date'; puts (Date.parse('${START_DATE}') + ${i}).strftime('%Y-%m-%d')")

  # Title
  topic="${topics[$(( i % n_topics ))]}"
  printf -v num "%03d" $((i+1))
  # title="DevOps Note ${num} - ${topic}"
  title="${topic}"

  # Slug and filename
  slug="$(make_slug "$title")"
  path="${TARGET_DIR}/${date}-${slug}.md"
  filename="$(next_available_filename "$path")"

  # Tags (simple round-robin)
  t1="${tags_pool[$(( i % n_tags ))]}"
  t2="${tags_pool[$(((i + 7) % n_tags))]}"
  t3="${tags_pool[$(((i + 13) % n_tags))]}"
  tags_yaml="[$t1, $t2, $t3]"

  # Categories
  primary_cat="$(derive_primary_category "$title" "$t1" "$t2" "$t3")"
  # Always append "Tutorial" as the second category
  echo "Primary category for '$title': $primary_cat"
  categories_yaml='["'$primary_cat'"]'

  # Body
  read -r -d '' body <<'EOT' || true
This post covers a concise, actionable tip for daily DevOps work.

- What: Brief guidance and checklist
- Why: Reliability, speed, and safety
- How: Minimal example and references
EOT

  # Write file
  cat >"$filename" <<EOF
---
layout: post
title: "${title}"
date: ${date} 00:00:00 +0900
tags: ${tags_yaml}
categories: ${categories_yaml}
---

${body}
EOF

  echo "Created: $filename"
done

echo "Done."
