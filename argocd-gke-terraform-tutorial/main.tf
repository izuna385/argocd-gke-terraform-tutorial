# GKEクラスターの作成
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region

  # 初期ノードプールを削除して、別途管理
  remove_default_node_pool = true
  initial_node_count       = 1

  # カスタムネットワーク設定
  network = google_compute_network.gke_network.name
  # auto_create_subnetworks = true の場合、サブネットは自動作成されるため指定不要

  # 削除保護を無効化
  deletion_protection = true

  # Workload Identity の有効化
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # リリースチャンネル
  release_channel {
    channel = "REGULAR"
  }
}

# ノードプールの作成
resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.cluster_name}-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count

  node_config {
    preemptible  = true
    machine_type = var.machine_type

    # Google サービスアカウント
    service_account = google_service_account.gke_node_sa.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # Workload Identity の設定
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
}

# GKEノード用のサービスアカウント
resource "google_service_account" "gke_node_sa" {
  account_id   = "${var.cluster_name}-node-sa"
  display_name = "GKE Node Service Account"
}

# リージョナル静的IPの予約（GKE LoadBalancer用）
resource "google_compute_address" "argocd_ip" {
  name         = "argocd-static-ip"
  description  = "Static IP for ArgoCD LoadBalancer"
  region       = var.region
  address_type = "EXTERNAL"
}

# グローバル静的IPの予約（Ingress用）
resource "google_compute_global_address" "argocd_ingress_ip" {
  name        = "argocd-ingress-ip"
  description = "Static IP for ArgoCD Ingress"
}

# Google Managed SSL証明書
resource "google_compute_managed_ssl_certificate" "argocd_ssl" {
  name = "argocd-ssl-cert"

  managed {
    domains = ["argocd.${var.domain_name}"]
  }
}

# 手動で作成したSSL証明書をTerraformで管理（既存リソースをインポート用）
resource "google_compute_managed_ssl_certificate" "argocd_manual_ssl" {
  name = "argocd-manual-ssl-cert"

  managed {
    domains = ["argocd.${var.domain_name}"]
  }

  lifecycle {
    # 既存のリソースを保護
    prevent_destroy = true
  }
}

# HTTPSターゲットプロキシ
resource "google_compute_target_https_proxy" "argocd_https_proxy" {
  name             = "argocd-https-proxy"
  url_map          = "k8s2-um-fweqqkn5-argocd-argocd-server-ingress-zi04abxy"
  ssl_certificates = [google_compute_managed_ssl_certificate.argocd_manual_ssl.id]

  depends_on = [google_compute_managed_ssl_certificate.argocd_manual_ssl]
}

# HTTPSフォワーディングルール
resource "google_compute_global_forwarding_rule" "argocd_https_forwarding_rule" {
  name       = "argocd-https-forwarding-rule"
  target     = google_compute_target_https_proxy.argocd_https_proxy.id
  port_range = "443"
  ip_address = google_compute_global_address.argocd_ingress_ip.address

  depends_on = [google_compute_target_https_proxy.argocd_https_proxy]
}

# IAP用のOAuth設定は手動で行う必要があります
# 1. Google Cloud Console > APIs & Services > OAuth consent screen
# 2. External を選択
# 3. アプリ名: ArgoCD IAP
# 4. サポートメール: h.hiroshi.nlp@gmail.com
# 5. 承認済みドメイン: gke-argocd-terraform-tutorial.com
# 6. APIs & Services > Credentials > Create Credentials > OAuth 2.0 Client IDs
# 7. Application type: Web application
# 8. Name: ArgoCD IAP Client
# 9. Authorized redirect URIs: https://argocd.gke-argocd-terraform-tutorial.com/_gcp_gatekeeper/authenticate

# Cloud DNS マネージドゾーンの作成
resource "google_dns_managed_zone" "argocd_zone" {
  name        = "argocd-zone"
  dns_name    = "${var.domain_name}."
  description = "Zone for ArgoCD"
}

# A レコードの作成（Ingress用）
resource "google_dns_record_set" "argocd_a_record" {
  name = "argocd.${var.domain_name}."
  type = "A"
  ttl  = 300

  managed_zone = google_dns_managed_zone.argocd_zone.name

  rrdatas = [google_compute_global_address.argocd_ingress_ip.address]
}
