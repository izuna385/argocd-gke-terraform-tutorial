# ArgoCD GKE Terraform Tutorial - アーキテクチャ図

## 概要
このプロジェクトは、Terraform、GKE、ArgoCDを組み合わせたCI/CDパイプラインとHTTPS対応のWebアプリケーション配信基盤です。

---

## 1. ドメイン・ネットワーク・Ingress・Backend Service・Network Rule の関係

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Internet                                        │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ DNS Resolution
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        Cloud DNS Zone                                       │
│  gke-argocd-terraform-tutorial.com                                         │
│  ├─ A Record: argocd.gke-argocd-terraform-tutorial.com → 34.110.224.66    │
│  └─ NS Records: ns-cloud-*.googledomains.com                               │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ IP: 34.110.224.66
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                     Google Cloud Load Balancer                             │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Global Static IP                                 │   │
│  │              argocd-ingress-ip                                      │   │
│  │                34.110.224.66                                        │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                          ┌─────────┴─────────┐                             │
│                          │                   │                             │
│                          ▼                   ▼                             │
│  ┌─────────────────────────────┐   ┌─────────────────────────────┐         │
│  │    HTTP Forwarding Rule     │   │   HTTPS Forwarding Rule     │         │
│  │         Port: 80            │   │         Port: 443           │         │
│  └─────────────────────────────┘   └─────────────────────────────┘         │
│                  │                                   │                     │
│                  ▼                                   ▼                     │
│  ┌─────────────────────────────┐   ┌─────────────────────────────┐         │
│  │     HTTP Target Proxy       │   │    HTTPS Target Proxy       │         │
│  │    (Kubernetes managed)     │   │     argocd-https-proxy      │         │
│  └─────────────────────────────┘   └─────────────────────────────┘         │
│                  │                                   │                     │
│                  │                                   │                     │
│                  └─────────┬─────────────────────────┘                     │
│                            │                                               │
│                            ▼                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      URL Map                                        │   │
│  │           k8s2-um-fweqqkn5-argocd-argocd-server-ingress-zi04abxy   │   │
│  │                                                                     │   │
│  │  Rules:                                                             │   │
│  │  ├─ Host: argocd.gke-argocd-terraform-tutorial.com                 │   │
│  │  └─ Path: /* → Backend Service                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                                    ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Backend Service                                  │   │
│  │              k8s2-be-*-argocd-argocd-server                        │   │
│  │                                                                     │   │
│  │  Health Check: /                                                    │   │
│  │  Protocol: HTTP                                                     │   │
│  │  Port: 80                                                           │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ Load Balancing
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              GKE Cluster                                   │
│                         argocd-gke-cluster1                                │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                        Node Pool                                    │   │
│  │                                                                     │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │                    ArgoCD Namespace                         │   │   │
│  │  │                                                             │   │   │
│  │  │  ┌─────────────────────────────────────────────────────┐   │   │   │
│  │  │  │              ArgoCD Server Service                  │   │   │   │
│  │  │  │                Type: NodePort                       │   │   │   │
│  │  │  │                Port: 80 → 8080                     │   │   │   │
│  │  │  └─────────────────────────────────────────────────────┘   │   │   │
│  │  │                            │                               │   │   │
│  │  │                            ▼                               │   │   │
│  │  │  ┌─────────────────────────────────────────────────────┐   │   │   │
│  │  │  │              ArgoCD Server Pod                      │   │   │   │
│  │  │  │                Port: 8080                           │   │   │   │
│  │  │  │                                                     │   │   │   │
│  │  │  │  ┌─────────────────────────────────────────────┐   │   │   │   │
│  │  │  │  │            ArgoCD Application               │   │   │   │   │
│  │  │  │  │              Web UI & API                   │   │   │   │   │
│  │  │  │  └─────────────────────────────────────────────┘   │   │   │   │
│  │  │  └─────────────────────────────────────────────────────┘   │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                         SSL Certificate                                    │
│                    argocd-manual-ssl-cert                                  │
│                                                                             │
│  Domain: argocd.gke-argocd-terraform-tutorial.com                          │
│  Status: ACTIVE                                                             │
│  Type: Google Managed                                                       │
│  Auto-renewal: Enabled                                                      │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                        Network Security                                    │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Firewall Rules                                   │   │
│  │                                                                     │   │
│  │  ├─ k8s-fw-*-argocd-argocd-server-ingress (HTTP/HTTPS)             │   │
│  │  ├─ gke-argocd-gke-cluster1-* (Node communication)                 │   │
│  │  └─ default-allow-* (Basic connectivity)                           │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

### ネットワークフロー
1. **DNS解決**: `argocd.gke-argocd-terraform-tutorial.com` → `34.110.224.66`
2. **Load Balancer**: グローバル静的IPでトラフィック受信
3. **SSL終端**: HTTPS Target ProxyでSSL証明書による暗号化
4. **ルーティング**: URL MapでBackend Serviceにルーティング
5. **負荷分散**: Backend ServiceがGKEノードに負荷分散
6. **Pod配信**: NodePortサービス経由でArgoCD Podに配信

---

## 2. GCS・Terraform・GKE の関係

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            Developer                                        │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Local Development                                │   │
│  │                                                                     │   │
│  │  ├─ terraform/                                                      │   │
│  │  │  ├─ main.tf                                                      │   │
│  │  │  ├─ variables.tf                                                 │   │
│  │  │  ├─ outputs.tf                                                   │   │
│  │  │  └─ terraform.tfvars                                             │   │
│  │  │                                                                  │   │
│  │  └─ kubectl configurations                                          │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ terraform init/plan/apply
                                    │ kubectl commands
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        Google Cloud Platform                               │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                  Cloud Storage (GCS)                                │   │
│  │              terraform-state-bucket-unique                          │   │
│  │                                                                     │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │                Terraform State                              │   │   │
│  │  │                                                             │   │   │
│  │  │  ├─ terraform.tfstate                                       │   │   │
│  │  │  ├─ terraform.tfstate.backup                                │   │   │
│  │  │  └─ .terraform.lock.hcl                                     │   │   │
│  │  │                                                             │   │   │
│  │  │  State includes:                                            │   │   │
│  │  │  ├─ GKE Cluster configuration                               │   │   │
│  │  │  ├─ Network resources                                       │   │   │
│  │  │  ├─ Static IP addresses                                     │   │   │
│  │  │  ├─ SSL certificates                                        │   │   │
│  │  │  ├─ Load balancer components                                │   │   │
│  │  │  └─ IAM roles and bindings                                  │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                                    │ State Management                       │
│                                    │ Resource Tracking                      │
│                                    ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Terraform Engine                                 │   │
│  │                                                                     │   │
│  │  Resource Management:                                               │   │
│  │  ├─ Plan: Compare desired vs current state                         │   │
│  │  ├─ Apply: Create/Update/Delete resources                          │   │
│  │  ├─ Destroy: Clean up resources                                    │   │
│  │  └─ Import: Bring existing resources under management              │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                                    │ API Calls                              │
│                                    ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                  Google Cloud APIs                                  │   │
│  │                                                                     │   │
│  │  ├─ Compute Engine API (GKE, Load Balancer, Firewall)              │   │
│  │  ├─ Container API (GKE Cluster, Node Pools)                        │   │
│  │  ├─ DNS API (Cloud DNS, Domain management)                         │   │
│  │  ├─ Certificate Manager API (SSL Certificates)                     │   │
│  │  └─ IAM API (Service Accounts, Roles)                              │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                                    │ Resource Creation/Management           │
│                                    ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                Google Kubernetes Engine (GKE)                      │   │
│  │                    argocd-gke-cluster1                             │   │
│  │                                                                     │   │
│  │  Cluster Configuration:                                             │   │
│  │  ├─ Location: asia-northeast1                                       │   │
│  │  ├─ Version: Latest stable                                          │   │
│  │  ├─ Node Pool: 3 nodes (e2-medium)                                 │   │
│  │  ├─ Network: VPC with private nodes                                │   │
│  │  ├─ Workload Identity: Enabled                                     │   │
│  │  └─ Monitoring: Cloud Operations enabled                           │   │
│  │                                                                     │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │                    Master Node                              │   │   │
│  │  │              (Google Managed)                               │   │   │
│  │  │                                                             │   │   │
│  │  │  ├─ Kubernetes API Server                                   │   │   │
│  │  │  ├─ etcd                                                    │   │   │
│  │  │  ├─ Controller Manager                                      │   │   │
│  │  │  └─ Scheduler                                               │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  │                                                                     │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │                   Worker Nodes                              │   │   │
│  │  │                                                             │   │   │
│  │  │  Node 1: gke-argocd-gke-cluster1-default-pool-*            │   │   │
│  │  │  ├─ kubelet                                                 │   │   │
│  │  │  ├─ kube-proxy                                              │   │   │
│  │  │  ├─ Container Runtime (containerd)                          │   │   │
│  │  │  └─ ArgoCD Pods                                             │   │   │
│  │  │                                                             │   │   │
│  │  │  Node 2: gke-argocd-gke-cluster1-default-pool-*            │   │   │
│  │  │  Node 3: gke-argocd-gke-cluster1-default-pool-*            │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Network Resources                                │   │
│  │                                                                     │   │
│  │  ├─ VPC Network: default                                            │   │
│  │  ├─ Subnets: Regional subnets                                       │   │
│  │  ├─ Static IPs:                                                     │   │
│  │  │  ├─ argocd-loadbalancer-ip (Regional): 104.198.115.185          │   │
│  │  │  └─ argocd-ingress-ip (Global): 34.110.224.66                   │   │
│  │  ├─ Load Balancer: Google Cloud Load Balancer                      │   │
│  │  ├─ SSL Certificate: argocd-manual-ssl-cert                         │   │
│  │  └─ Firewall Rules: GKE managed + custom rules                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                        State Synchronization                               │
│                                                                             │
│  Local Terraform ←→ GCS State ←→ Google Cloud Resources                    │
│                                                                             │
│  ├─ terraform plan: Compare local config with remote state                 │
│  ├─ terraform apply: Update remote state and resources                     │
│  ├─ terraform refresh: Sync state with actual resources                    │
│  └─ terraform import: Import existing resources to state                   │
└─────────────────────────────────────────────────────────────────────────────┘
```

### インフラ管理フロー
1. **開発者**: Terraformコードを作成・編集
2. **State管理**: GCSでTerraformステートを集中管理
3. **リソース作成**: Terraform → Google Cloud APIs → 実際のリソース
4. **GKE管理**: Terraformで宣言的にクラスター構成を管理
5. **状態同期**: ローカル設定 ↔ GCSステート ↔ 実際のリソース

---

## 3. Helm・GKE・ArgoCD・App・Artifact Registry の関係

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            Developer                                        │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                  Application Development                            │   │
│  │                                                                     │   │
│  │  ├─ app/                                                            │   │
│  │  │  ├─ Dockerfile                                                   │   │
│  │  │  ├─ source code                                                  │   │
│  │  │  └─ k8s-manifests/                                               │   │
│  │  │     ├─ deployment.yaml                                           │   │
│  │  │     ├─ service.yaml                                              │   │
│  │  │     └─ ingress.yaml                                              │   │
│  │  │                                                                  │   │
│  │  └─ Helm Charts (for ArgoCD)                                        │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ docker build & push
                                    │ helm install/upgrade
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        Google Cloud Platform                               │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Artifact Registry                                │   │
│  │              asia-northeast1-docker.pkg.dev                        │   │
│  │                                                                     │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │                Container Images                             │   │   │
│  │  │                                                             │   │   │
│  │  │  ├─ my-app:v1.0.0                                           │   │   │
│  │  │  ├─ my-app:v1.1.0                                           │   │   │
│  │  │  ├─ my-app:latest                                            │   │   │
│  │  │  └─ other-microservices:*                                   │   │   │
│  │  │                                                             │   │   │
│  │  │  Image Security:                                            │   │   │
│  │  │  ├─ Vulnerability Scanning                                  │   │   │
│  │  │  ├─ Binary Authorization                                    │   │   │
│  │  │  └─ Access Control (IAM)                                    │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                                    │ Image Pull                             │
│                                    ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                Google Kubernetes Engine (GKE)                      │   │
│  │                    argocd-gke-cluster1                             │   │
│  │                                                                     │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │                    ArgoCD Namespace                         │   │   │
│  │  │                                                             │   │   │
│  │  │  ┌─────────────────────────────────────────────────────┐   │   │   │
│  │  │  │              ArgoCD Components                      │   │   │   │
│  │  │  │                                                     │   │   │   │
│  │  │  │  ┌─────────────────────────────────────────────┐   │   │   │   │
│  │  │  │  │            ArgoCD Server                    │   │   │   │   │
│  │  │  │  │              (Web UI & API)                 │   │   │   │   │
│  │  │  │  │                                             │   │   │   │   │
│  │  │  │  │  ├─ Application Management                  │   │   │   │   │
│  │  │  │  │  ├─ Git Repository Sync                     │   │   │   │   │
│  │  │  │  │  ├─ Deployment Status                       │   │   │   │   │
│  │  │  │  │  └─ RBAC & User Management                  │   │   │   │   │
│  │  │  │  └─────────────────────────────────────────────┘   │   │   │   │
│  │  │  │                            │                       │   │   │   │
│  │  │  │  ┌─────────────────────────────────────────────┐   │   │   │   │
│  │  │  │  │         ArgoCD Repo Server                  │   │   │   │   │
│  │  │  │  │                                             │   │   │   │   │
│  │  │  │  │  ├─ Git Repository Cloning                  │   │   │   │   │
│  │  │  │  │  ├─ Manifest Generation                     │   │   │   │   │
│  │  │  │  │  ├─ Helm Template Rendering                 │   │   │   │   │
│  │  │  │  │  └─ Kustomize Processing                    │   │   │   │   │
│  │  │  │  └─────────────────────────────────────────────┘   │   │   │   │
│  │  │  │                            │                       │   │   │   │
│  │  │  │  ┌─────────────────────────────────────────────┐   │   │   │   │
│  │  │  │  │      ArgoCD Application Controller          │   │   │   │   │
│  │  │  │  │                                             │   │   │   │   │
│  │  │  │  │  ├─ Sync Loop (every 3 minutes)             │   │   │   │   │
│  │  │  │  │  ├─ Drift Detection                         │   │   │   │   │
│  │  │  │  │  ├─ Auto-sync (if enabled)                  │   │   │   │   │
│  │  │  │  │  └─ Health Monitoring                       │   │   │   │   │
│  │  │  │  └─────────────────────────────────────────────┘   │   │   │   │
│  │  │  └─────────────────────────────────────────────────────┘   │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  │                                    │                                │   │
│  │                                    │ Kubernetes API                 │   │
│  │                                    ▼                                │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │                  Application Namespaces                    │   │   │
│  │  │                                                             │   │   │
│  │  │  ┌─────────────────────────────────────────────────────┐   │   │   │
│  │  │  │                  my-app                             │   │   │   │
│  │  │  │                                                     │   │   │   │
│  │  │  │  ┌─────────────────────────────────────────────┐   │   │   │   │
│  │  │  │  │              Deployment                     │   │   │   │   │
│  │  │  │  │                                             │   │   │   │   │
│  │  │  │  │  ├─ Replicas: 3                             │   │   │   │   │
│  │  │  │  │  ├─ Image: asia-northeast1-docker.pkg.dev/  │   │   │   │   │
│  │  │  │  │  │         project/my-app:v1.1.0            │   │   │   │   │
│  │  │  │  │  ├─ Rolling Update Strategy                 │   │   │   │   │
│  │  │  │  │  └─ Resource Limits                         │   │   │   │   │
│  │  │  │  └─────────────────────────────────────────────┘   │   │   │   │
│  │  │  │                            │                       │   │   │   │
│  │  │  │  ┌─────────────────────────────────────────────┐   │   │   │   │
│  │  │  │  │                Service                      │   │   │   │   │
│  │  │  │  │                                             │   │   │   │   │
│  │  │  │  │  ├─ Type: ClusterIP                         │   │   │   │   │
│  │  │  │  │  ├─ Port: 80 → 8080                         │   │   │   │   │
│  │  │  │  │  └─ Selector: app=my-app                    │   │   │   │   │
│  │  │  │  └─────────────────────────────────────────────┘   │   │   │   │
│  │  │  │                            │                       │   │   │   │
│  │  │  │  ┌─────────────────────────────────────────────┐   │   │   │   │
│  │  │  │  │               Ingress                       │   │   │   │   │
│  │  │  │  │                                             │   │   │   │   │
│  │  │  │  │  ├─ Host: my-app.example.com                │   │   │   │   │
│  │  │  │  │  ├─ TLS: Enabled                            │   │   │   │   │
│  │  │  │  │  └─ Backend: my-app service                 │   │   │   │   │
│  │  │  │  └─────────────────────────────────────────────┘   │   │   │   │
│  │  │  └─────────────────────────────────────────────────────┘   │   │   │
│  │  │                                                             │   │   │
│  │  │  ┌─────────────────────────────────────────────────────┐   │   │   │
│  │  │  │              other-microservice                     │   │   │   │
│  │  │  │              (Similar structure)                    │   │   │   │
│  │  │  └─────────────────────────────────────────────────────┘   │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ▲
                                    │ Git Repository Sync
                                    │
┌─────────────────────────────────────────────────────────────────────────────┐
│                            Git Repository                                   │
│                         (GitHub/GitLab/etc.)                               │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Application Repository                           │   │
│  │                                                                     │   │
│  │  ├─ k8s-manifests/                                                  │   │
│  │  │  ├─ deployment.yaml                                              │   │
│  │  │  ├─ service.yaml                                                 │   │
│  │  │  └─ ingress.yaml                                                 │   │
│  │  │                                                                  │   │
│  │  ├─ helm-charts/                                                    │   │
│  │  │  ├─ Chart.yaml                                                   │   │
│  │  │  ├─ values.yaml                                                  │   │
│  │  │  └─ templates/                                                   │   │
│  │  │                                                                  │   │
│  │  └─ argocd-applications/                                            │   │
│  │     ├─ my-app.yaml                                                  │   │
│  │     └─ other-services.yaml                                          │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                            Helm Integration                                 │
│                                                                             │
│  Local Development:                                                         │
│  ├─ helm repo add argo https://argoproj.github.io/argo-helm                │
│  ├─ helm install argocd argo/argo-cd -n argocd                             │
│  ├─ helm upgrade argocd argo/argo-cd -n argocd --set server.service.type=NodePort │
│  └─ helm uninstall argocd -n argocd                                         │
│                                                                             │
│  ArgoCD Application Deployment:                                             │
│  ├─ Helm Charts in Git Repository                                           │
│  ├─ ArgoCD renders Helm templates                                           │
│  ├─ Applies rendered manifests to Kubernetes                               │
│  └─ Monitors for drift and auto-syncs                                      │
└─────────────────────────────────────────────────────────────────────────────┘
```

### アプリケーションデプロイメントフロー
1. **開発**: アプリケーションコード + Dockerfileを作成
2. **ビルド**: Docker imageをビルドしてArtifact Registryにプッシュ
3. **Helm管理**: ArgoCDをHelmでGKEにインストール
4. **GitOps**: アプリケーションマニフェストをGitリポジトリで管理
5. **ArgoCD同期**: Gitリポジトリを監視し、変更を自動でKubernetesに適用
6. **イメージプル**: KubernetesがArtifact Registryからコンテナイメージを取得
7. **継続的デプロイ**: コードプッシュ → イメージビルド → マニフェスト更新 → 自動デプロイ

---

## 4. 全体統合アーキテクチャ

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              DEVELOPER                                     │
│                                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐ │
│  │   Terraform     │  │   Application   │  │        Helm Charts          │ │
│  │   Code          │  │   Code          │  │                             │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        GOOGLE CLOUD PLATFORM                               │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      INFRASTRUCTURE LAYER                          │   │
│  │                                                                     │   │
│  │  GCS ←→ Terraform ←→ GKE + Network + DNS + SSL                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                                    ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      PLATFORM LAYER                                │   │
│  │                                                                     │   │
│  │  Artifact Registry ←→ GKE ←→ ArgoCD (Helm managed)                 │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                                    ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      APPLICATION LAYER                             │   │
│  │                                                                     │   │
│  │  Git Repository ←→ ArgoCD ←→ Applications (Kubernetes)              │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                                    ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      NETWORK LAYER                                  │   │
│  │                                                                     │   │
│  │  Internet ←→ DNS ←→ Load Balancer ←→ SSL ←→ Applications            │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

このアーキテクチャにより、Infrastructure as Code、GitOps、コンテナオーケストレーション、セキュアなネットワーキングが統合された現代的なクラウドネイティブプラットフォームが実現されています。 