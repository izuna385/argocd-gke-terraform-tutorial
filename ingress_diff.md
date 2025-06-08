# ArgoCD HTTPS構成 - Ingress vs 手動構成の比較と再構成手順

## 概要
ArgoCDにHTTPSアクセスを実現するための2つのアプローチの比較と、それぞれの再構成手順をまとめます。

## 1. Kubernetes Ingress構成（自動アプローチ）

### 特徴
- **宣言的設定**: YAML定義による自動構築
- **統合管理**: Kubernetesエコシステム内で完結
- **自動化**: SSL証明書の自動プロビジョニング
- **制約**: Google Cloud Load Balancerの詳細制御が困難

### 構成要素
```yaml
# Ingress
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-ingress
  annotations:
    kubernetes.io/ingress.global-static-ip-name: "argocd-ingress-ip"
    networking.gke.io/managed-certificates: "argocd-ssl-cert"
    kubernetes.io/ingress.class: "gce"

# ManagedCertificate
apiVersion: networking.gke.io/v1
kind: ManagedCertificate
metadata:
  name: argocd-ssl-cert
spec:
  domains:
    - argocd.gke-argocd-terraform-tutorial.com

# Service (NodePort)
apiVersion: v1
kind: Service
metadata:
  name: argocd-server
spec:
  type: NodePort
  ports:
    - port: 80
      targetPort: 8080
      protocol: TCP
```

### 再構成手順

#### 1. 現在の手動構成を削除
```bash
# HTTPSフォワーディングルール削除
gcloud compute forwarding-rules delete argocd-https-forwarding-rule --global --quiet

# HTTPSターゲットプロキシ削除
gcloud compute target-https-proxy delete argocd-https-proxy --quiet

# 手動SSL証明書削除
gcloud compute ssl-certificates delete argocd-manual-ssl-cert --quiet
```

#### 2. Terraformから手動リソースを削除
```bash
# Terraformステートから削除
terraform state rm google_compute_managed_ssl_certificate.argocd_manual_ssl
terraform state rm google_compute_target_https_proxy.argocd_https_proxy
terraform state rm google_compute_global_forwarding_rule.argocd_https_forwarding_rule

# terraform/main.tfから手動構成のリソース定義を削除
# - google_compute_managed_ssl_certificate.argocd_manual_ssl
# - google_compute_target_https_proxy.argocd_https_proxy
# - google_compute_global_forwarding_rule.argocd_https_forwarding_rule
```

#### 3. Kubernetes Ingressリソースを適用
```bash
# ManagedCertificateを作成
kubectl apply -f - <<EOF
apiVersion: networking.gke.io/v1
kind: ManagedCertificate
metadata:
  name: argocd-ssl-cert
  namespace: argocd
spec:
  domains:
    - argocd.gke-argocd-terraform-tutorial.com
EOF

# Ingressを作成
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: argocd
  annotations:
    kubernetes.io/ingress.global-static-ip-name: "argocd-ingress-ip"
    networking.gke.io/managed-certificates: "argocd-ssl-cert"
    kubernetes.io/ingress.class: "gce"
spec:
  rules:
  - host: argocd.gke-argocd-terraform-tutorial.com
    http:
      paths:
      - path: /*
        pathType: ImplementationSpecific
        backend:
          service:
            name: argocd-server
            port:
              number: 80
EOF
```

#### 4. サービスをNodePortに変更
```bash
# ArgoCD Helmの値を更新
helm upgrade argocd argo/argo-cd -n argocd --set server.service.type=NodePort
```

#### 5. 証明書のプロビジョニング確認
```bash
# ManagedCertificateの状態確認
kubectl get managedcertificate -n argocd argocd-ssl-cert -o yaml

# Ingressの状態確認
kubectl get ingress -n argocd argocd-server-ingress -o yaml

# Google Cloud SSL証明書の状態確認
gcloud compute ssl-certificates list
```

### 問題点と対処法
- **証明書プロビジョニング失敗**: HTTPアクセスが必要
- **HTTPS自動リダイレクト**: 証明書検証を阻害する可能性
- **デバッグ困難**: 自動構築のため問題の特定が困難

---

## 2. 手動構成（命令的アプローチ）

### 特徴
- **命令的設定**: Google Cloud CLIによる直接制御
- **段階的構築**: HTTP動作確認後にHTTPS追加
- **柔軟性**: 既存Kubernetesインフラとの組み合わせ
- **制御性**: 各コンポーネントの詳細制御が可能

### 構成要素
```
ブラウザ → DNS → 34.110.224.66 (グローバル静的IP)
         ↓
      HTTPS:443 → argocd-https-forwarding-rule
         ↓
      argocd-https-proxy → argocd-manual-ssl-cert
         ↓
      k8s2-um-... (Kubernetes URL Map) → Backend Service → ArgoCD Pod
```

### 再構成手順

#### 1. 前提条件の確認
```bash
# HTTPアクセスが正常動作していることを確認
curl -I http://argocd.gke-argocd-terraform-tutorial.com

# Kubernetes Ingressが存在し、URL Mapが作成されていることを確認
kubectl get ingress -n argocd
gcloud compute url-maps list | grep k8s2-um
```

#### 2. SSL証明書の作成
```bash
# Google Managed SSL証明書を作成
gcloud compute ssl-certificates create argocd-manual-ssl-cert \
  --domains=argocd.gke-argocd-terraform-tutorial.com \
  --global

# 証明書の状態確認（PROVISIONING → ACTIVE）
gcloud compute ssl-certificates describe argocd-manual-ssl-cert --global
```

#### 3. HTTPSターゲットプロキシの作成
```bash
# 既存のURL Mapを確認
URL_MAP=$(gcloud compute url-maps list --filter="name~k8s2-um.*argocd.*" --format="value(name)")

# HTTPSターゲットプロキシを作成
gcloud compute target-https-proxy create argocd-https-proxy \
  --url-map=$URL_MAP \
  --ssl-certificates=argocd-manual-ssl-cert
```

#### 4. HTTPSフォワーディングルールの作成
```bash
# HTTPSフォワーディングルールを作成
gcloud compute forwarding-rules create argocd-https-forwarding-rule \
  --global \
  --target-https-proxy=argocd-https-proxy \
  --ports=443 \
  --address=argocd-ingress-ip
```

#### 5. Terraformへのインポート
```bash
# 手動作成したリソースをTerraformにインポート
terraform import google_compute_managed_ssl_certificate.argocd_manual_ssl argocd-manual-ssl-cert
terraform import google_compute_target_https_proxy.argocd_https_proxy argocd-https-proxy
terraform import google_compute_global_forwarding_rule.argocd_https_forwarding_rule argocd-https-forwarding-rule

# terraform/main.tfに対応するリソース定義を追加
```

#### 6. Terraformリソース定義
```hcl
# SSL証明書
resource "google_compute_managed_ssl_certificate" "argocd_manual_ssl" {
  name = "argocd-manual-ssl-cert"
  managed {
    domains = ["argocd.gke-argocd-terraform-tutorial.com"]
  }
}

# HTTPSターゲットプロキシ
resource "google_compute_target_https_proxy" "argocd_https_proxy" {
  name             = "argocd-https-proxy"
  url_map          = data.google_compute_url_map.argocd_url_map.id
  ssl_certificates = [google_compute_managed_ssl_certificate.argocd_manual_ssl.id]
}

# HTTPSフォワーディングルール
resource "google_compute_global_forwarding_rule" "argocd_https_forwarding_rule" {
  name       = "argocd-https-forwarding-rule"
  target     = google_compute_target_https_proxy.argocd_https_proxy.id
  port_range = "443"
  ip_address = google_compute_global_address.argocd_ingress_ip.address
}

# URL Mapの参照
data "google_compute_url_map" "argocd_url_map" {
  name = "k8s2-um-fweqqkn5-argocd-argocd-server-ingress-zi04abxy"
}
```

#### 7. 動作確認
```bash
# HTTPSアクセステスト
curl -I https://argocd.gke-argocd-terraform-tutorial.com

# SSL証明書の確認
openssl s_client -connect argocd.gke-argocd-terraform-tutorial.com:443 -servername argocd.gke-argocd-terraform-tutorial.com < /dev/null

# DNS解決確認
nslookup argocd.gke-argocd-terraform-tutorial.com
```

---

## 3. 比較表

| 項目 | Kubernetes Ingress | 手動構成 |
|------|-------------------|----------|
| **設定方法** | YAML宣言的 | CLI命令的 |
| **管理** | Kubernetes統合 | Google Cloud直接 |
| **自動化** | 高い | 低い |
| **制御性** | 低い | 高い |
| **デバッグ** | 困難 | 容易 |
| **SSL証明書** | 自動プロビジョニング | 手動作成 |
| **失敗時の対処** | 困難 | 段階的対処可能 |
| **Terraform統合** | ネイティブ | インポート必要 |

## 4. 推奨アプローチ

### 開発・テスト環境
- **手動構成**を推奨
- 問題の特定と解決が容易
- 段階的な構築でリスク軽減

### 本番環境
- **Kubernetes Ingress**を推奨（動作確認後）
- 宣言的設定による管理性
- Kubernetesエコシステムとの統合

### ハイブリッドアプローチ
- 初期構築は手動で行い、動作確認後にIngress化
- 問題発生時は手動構成に戻して原因調査
- 段階的な移行でリスクを最小化

## 5. トラブルシューティング

### SSL証明書がACTIVEにならない場合
```bash
# HTTPアクセスが正常か確認
curl -I http://argocd.gke-argocd-terraform-tutorial.com

# DNS解決確認
dig argocd.gke-argocd-terraform-tutorial.com

# ファイアウォール確認
gcloud compute firewall-rules list --filter="name~k8s"
```

### DNS解決問題
```bash
# DNSキャッシュクリア
sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder

# 外部DNSでの確認
nslookup argocd.gke-argocd-terraform-tutorial.com 8.8.8.8

# 一時的なhosts設定
echo "34.110.224.66 argocd.gke-argocd-terraform-tutorial.com" | sudo tee -a /etc/hosts
```

### Kubernetes Ingressの問題
```bash
# Ingressコントローラーのログ確認
kubectl logs -n kube-system -l k8s-app=glbc

# ManagedCertificateの詳細確認
kubectl describe managedcertificate -n argocd argocd-ssl-cert

# Ingressイベント確認
kubectl describe ingress -n argocd argocd-server-ingress
``` 