#!/bin/bash

# Helm + Kustomize ワークフロースクリプト
# Helm Chartをテンプレート化してKustomizeで管理

set -e

# 変数定義
CHART_REPO="argo"
CHART_NAME="argo-cd"
VALUES_FILE="helm/argocd-values.yaml"
HELM_OUTPUT_DIR="helm-generated"
ENVIRONMENT=${1:-development}

echo "🚀 Helm + Kustomize ワークフロー開始..."
echo "📝 環境: ${ENVIRONMENT}"

# Helmリポジトリの更新
echo "📦 Helmリポジトリを更新中..."
helm repo add ${CHART_REPO} https://argoproj.github.io/argo-helm
helm repo update

# Helm Chartをテンプレート化（実際のKubernetesマニフェストを生成）
echo "🔧 Helm Chartをテンプレート化中..."
mkdir -p ${HELM_OUTPUT_DIR}
helm template argocd ${CHART_REPO}/${CHART_NAME} \
    --values ${VALUES_FILE} \
    --namespace argocd \
    --output-dir ${HELM_OUTPUT_DIR}

# 生成されたマニフェストを整理
echo "📁 生成されたマニフェストを整理中..."
find ${HELM_OUTPUT_DIR} -name "*.yaml" -exec mv {} ${HELM_OUTPUT_DIR}/ \;
find ${HELM_OUTPUT_DIR} -type d -empty -delete

# Kustomizeでオーバーレイを適用
echo "🎨 Kustomizeでオーバーレイを適用中..."
kustomize build kustomize/overlays/${ENVIRONMENT} > final-manifests-${ENVIRONMENT}.yaml

echo "✅ 最終マニフェストが生成されました: final-manifests-${ENVIRONMENT}.yaml"

# 適用オプション
read -p "生成されたマニフェストを適用しますか？ (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Kubernetesに適用中..."
    kubectl apply -f final-manifests-${ENVIRONMENT}.yaml
    echo "✅ 適用完了！"
else
    echo "📄 マニフェストファイルを確認してから手動で適用してください"
fi

# クリーンアップオプション
read -p "一時ファイルを削除しますか？ (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf ${HELM_OUTPUT_DIR}
    echo "🧹 一時ファイルを削除しました"
fi

echo "🎉 ワークフロー完了！" 