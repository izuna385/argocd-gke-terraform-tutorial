variable "project_id" {
  description = "Google Cloud プロジェクトID"
  type        = string
}

variable "region" {
  description = "Google Cloud リージョン"
  type        = string
  default     = "asia-northeast1"
}

variable "cluster_name" {
  description = "GKE クラスター名"
  type        = string
  default     = "argocd-gke-cluster"
}

variable "node_count" {
  description = "GKE ノード数"
  type        = number
  default     = 2
}

variable "machine_type" {
  description = "GKE ノードのマシンタイプ"
  type        = string
  default     = "e2-medium"
}

variable "domain_name" {
  description = "ドメイン名"
  type        = string
}

variable "support_email" {
  description = "IAP OAuth同意画面用のサポートメールアドレス"
  type        = string
}
