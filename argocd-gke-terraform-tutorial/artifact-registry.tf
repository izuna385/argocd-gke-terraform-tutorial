# Artifact Registry リポジトリの作成
resource "google_artifact_registry_repository" "argocd_app_repo" {
  location      = var.region
  repository_id = "argocd-app"
  description   = "Docker repository for ArgoCD applications"
  format        = "DOCKER"

  # クリーンアップポリシー（シンプル版）
  cleanup_policies {
    id     = "delete-old-untagged"
    action = "DELETE"
    
    condition {
      tag_state = "UNTAGGED"
      older_than = "2592000s"  # 30日
    }
  }

  cleanup_policies {
    id     = "keep-recent-versions"
    action = "KEEP"
    
    most_recent_versions {
      keep_count = 10
    }
  }
}

