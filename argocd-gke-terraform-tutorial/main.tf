

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

# 静的グローバルIPの予約
resource "google_compute_global_address" "argocd_ip" {
  name        = "argocd-static-ip"
  description = "Static IP for ArgoCD ingress"
}

# Cloud DNS マネージドゾーンの作成
resource "google_dns_managed_zone" "argocd_zone" {
  name        = "argocd-zone"
  dns_name    = "${var.domain_name}."
  description = "Zone for ArgoCD"
}

# A レコードの作成
resource "google_dns_record_set" "argocd_a_record" {
  name = "argocd.${var.domain_name}."
  type = "A"
  ttl  = 300

  managed_zone = google_dns_managed_zone.argocd_zone.name

  rrdatas = [google_compute_global_address.argocd_ip.address]
}
