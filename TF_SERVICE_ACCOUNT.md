# Terraform サービスアカウント設定手順

このドキュメントでは、Terraform用のサービスアカウントを作成し、必要な権限を付与する手順を説明します。

## 前提条件

- Google Cloud Platform プロジェクトが作成済み
- `gcloud` CLI がインストール・認証済み
- 適切なプロジェクトが設定済み

## 1. サービスアカウントの作成

```bash
gcloud iam service-accounts create terraform-sa \
  --display-name="Terraform Service Account" \
  --description="Service account for Terraform operations"
```

## 2. 必要な権限の付与

プロジェクトIDを取得し、Terraformサービスアカウントに必要な権限を付与します：

```bash
PROJECT_ID=$(gcloud config get-value project)

# GKE関連の権限
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:terraform-sa@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/container.admin"

# Compute Engine関連の権限（静的IP、ネットワーク等）
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:terraform-sa@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/compute.admin"

# DNS関連の権限
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:terraform-sa@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/dns.admin"

# IAM関連の権限（サービスアカウント作成用）
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:terraform-sa@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountAdmin"

# サービスアカウントユーザー権限
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:terraform-sa@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"
```

## 3. 認証キーファイルの作成

```bash
PROJECT_ID=$(gcloud config get-value project)
gcloud iam service-accounts keys create terraform-sa-key.json \
  --iam-account=terraform-sa@$PROJECT_ID.iam.gserviceaccount.com
```

## 付与された権限の詳細

| 権限 | 説明 | 用途 |
|------|------|------|
| `roles/container.admin` | GKE管理者 | GKEクラスターとノードプールの作成・管理 |
| `roles/compute.admin` | Compute Engine管理者 | 静的IP、ネットワーク、ファイアウォールルールの管理 |
| `roles/dns.admin` | DNS管理者 | Cloud DNSマネージドゾーンとレコードの管理 |
| `roles/iam.serviceAccountAdmin` | サービスアカウント管理者 | GKEノード用サービスアカウントの作成・管理 |
| `roles/iam.serviceAccountUser` | サービスアカウントユーザー | サービスアカウントの使用権限 |

## 4. Terraformでの使用方法

### 環境変数での認証

```bash
export GOOGLE_APPLICATION_CREDENTIALS="./terraform-sa-key.json"
```

### Terraformプロバイダー設定

```hcl
provider "google" {
  credentials = file("terraform-sa-key.json")
  project     = var.project_id
  region      = var.region
}
```

## セキュリティ注意事項

⚠️ **重要**: 
- `terraform-sa-key.json` ファイルは機密情報です
- このファイルをGitリポジトリにコミットしないでください
- `.gitignore` ファイルに追加して除外してください
- 本番環境では、より安全な認証方法（Workload Identity等）の使用を検討してください

## トラブルシューティング

### 権限不足エラーが発生した場合

1. サービスアカウントに適切な権限が付与されているか確認
2. プロジェクトIDが正しく設定されているか確認
3. 認証キーファイルのパスが正しいか確認

### サービスアカウントの確認

```bash
# サービスアカウント一覧の確認
gcloud iam service-accounts list

# 特定のサービスアカウントの権限確認
PROJECT_ID=$(gcloud config get-value project)
gcloud projects get-iam-policy $PROJECT_ID \
  --flatten="bindings[].members" \
  --format="table(bindings.role)" \
  --filter="bindings.members:terraform-sa@$PROJECT_ID.iam.gserviceaccount.com"
```

## クリーンアップ

サービスアカウントが不要になった場合の削除手順：

```bash
PROJECT_ID=$(gcloud config get-value project)

# サービスアカウントの削除
gcloud iam service-accounts delete terraform-sa@$PROJECT_ID.iam.gserviceaccount.com

# 認証キーファイルの削除
rm terraform-sa-key.json
``` 