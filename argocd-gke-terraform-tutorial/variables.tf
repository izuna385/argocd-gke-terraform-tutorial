variable "project_id" {
  description = "GCP プロジェクト ID"
  type        = string
}

variable "region" {
  description = "GCP リージョン"
  type        = string
  default     = "asia-northeast1"
}

variable "cluster_name" {
  description = "GKE クラスター名"
  type        = string
  default     = "argocd-gke-cluster1"
}

variable "node_count" {
  description = "ノード数"
  type        = number
  default     = 1
}

variable "machine_type" {
  description = "マシンタイプ"
  type        = string
  default     = "e2-medium"
}

variable "domain_name" {
  description = "独自ドメイン名（例: example.com）"
  type        = string
}
