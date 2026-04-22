---
title: Kubernetes Deployment
sidebar_position: 2
description: Deploy SkillHub in a Kubernetes cluster
---

# Kubernetes Deployment

This document describes how to deploy SkillHub in a Kubernetes cluster.

## Prerequisites

- Kubernetes 1.24+
- kubectl configured
- Helm 3.0+ (optional)
- An available persistent storage class

## Deployment Manifests

The project provides Kubernetes deployment manifests:

```bash
cd deploy/k8s

# 1. Create namespace
kubectl create namespace skillhub

# 2. Configure Secret
cp secret.yaml.example secret.yaml
# Edit secret.yaml and fill in real credentials

# 3. Apply configuration
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml

# 4. Deploy services
kubectl apply -f backend-deployment.yaml
kubectl apply -f frontend-deployment.yaml
kubectl apply -f services.yaml

# 5. Configure Ingress
kubectl apply -f ingress.yaml
```

## High Availability Configuration

- At least 2 replicas are recommended for both backend and frontend
- PostgreSQL uses primary-replica replication
- Redis uses Sentinel or Cluster mode
- Storage uses highly available object storage (e.g., MinIO cluster or cloud provider OSS)

## Next Steps

- [Configuration Reference](./configuration) - Detailed configuration options
