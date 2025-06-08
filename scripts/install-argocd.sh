#!/bin/bash

# ArgoCD Helm Chart インストールスクリプト
# このスクリプトでインストール手順をコード化

set -e

echo "🚀 ArgoCD Helm Chart インストール開始..."

# 変数定義
NAMESPACE="argocd"
RELEASE_NAME="argocd"
CHART_REPO="argo"
CHART_NAME="argo-cd"
VALUES_FILE="helm/argocd-values.yaml"

# Helmリポジトリの追加・更新
echo "📦 Helmリポジトリを追加・更新中..."
helm repo add ${CHART_REPO} https://argoproj.github.io/argo-helm
helm repo update

# 名前空間の作成
echo "🏗️  名前空間 '${NAMESPACE}' を作成中..."
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# ArgoCDのインストール
echo "⚙️  ArgoCDをインストール中..."
if [ -f "${VALUES_FILE}" ]; then
    echo "📄 values.yamlファイルを使用: ${VALUES_FILE}"
    helm upgrade --install ${RELEASE_NAME} ${CHART_REPO}/${CHART_NAME} \
        --namespace ${NAMESPACE} \
        --values ${VALUES_FILE} \
        --wait
else
    echo "⚠️  values.yamlファイルが見つかりません: ${VALUES_FILE}"
    echo "デフォルト設定でインストールします..."
    helm upgrade --install ${RELEASE_NAME} ${CHART_REPO}/${CHART_NAME} \
        --namespace ${NAMESPACE} \
        --set server.service.type=NodePort \
        --wait
fi

# インストール確認
echo "✅ インストール完了確認..."
helm list -n ${NAMESPACE}
kubectl get pods -n ${NAMESPACE}

# 初期パスワードの取得
echo "🔑 ArgoCD初期パスワードを取得中..."
ARGOCD_PASSWORD=$(kubectl -n ${NAMESPACE} get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD管理者パスワード: ${ARGOCD_PASSWORD}"

echo "🎉 ArgoCDのインストールが完了しました！"
echo "📝 アクセス情報:"
echo "   URL: https://argocd.gke-argocd-terraform-tutorial.com"
echo "   ユーザー名: admin"
echo "   パスワード: ${ARGOCD_PASSWORD}" 