
# 1. Artifact Registryリポジトリ作成（まだの場合）
gcloud artifacts repositories create argocd-app \
    --repository-format=docker \
    --location=asia-northeast1

# 2. Docker認証設定
gcloud auth configure-docker asia-northeast1-docker.pkg.dev

# 3. Skaffoldでビルド・プッシュ
skaffold build