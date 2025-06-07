output "cluster_name" {
  description = "GKE クラスター名"
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "GKE クラスターエンドポイント"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "cluster_location" {
  description = "GKE クラスターロケーション"
  value       = google_container_cluster.primary.location
}

output "argocd_static_ip" {
  description = "ArgoCD用の静的IP"
  value       = google_compute_global_address.argocd_ip.address
}

output "argocd_domain" {
  description = "ArgoCD のドメイン"
  value       = "argocd.${var.domain_name}"
}

output "dns_name_servers" {
  description = "DNS ネームサーバー"
  value       = google_dns_managed_zone.argocd_zone.name_servers
}

output "kubectl_config_command" {
  description = "kubectl 設定コマンド"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region ${google_container_cluster.primary.location} --project ${var.project_id}"
}

output "tf_state_bucket" {
  description = "Terraform状態保存用GCSバケット"
  value       = "gs://gcp-iap-test-442622-tf-state"
}

output "artifact_registry_repository" {
  description = "Artifact Registry リポジトリURL"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.argocd_app_repo.repository_id}"
}

output "docker_push_command" {
  description = "Docker認証設定コマンド"
  value       = "gcloud auth configure-docker ${var.region}-docker.pkg.dev"
}
