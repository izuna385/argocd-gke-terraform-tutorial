# ArgoCD IAP (Identity-Aware Proxy) 設定手順

## 1. OAuth同意画面の設定

1. [Google Cloud Console](https://console.cloud.google.com/) にアクセス
2. プロジェクト `gcp-iap-test-442622` を選択
3. **APIs & Services** > **OAuth consent screen** に移動
4. **External** を選択して **CREATE** をクリック
5. 以下の情報を入力：
   - **App name**: `ArgoCD IAP`
   - **User support email**: `h.hiroshi.nlp@gmail.com`
   - **Developer contact information**: `h.hiroshi.nlp@gmail.com`
6. **Authorized domains** セクションで **ADD DOMAIN** をクリック
   - ドメイン: `gke-argocd-terraform-tutorial.com`
7. **SAVE AND CONTINUE** をクリック
8. **Scopes** 画面で **SAVE AND CONTINUE** をクリック（デフォルトのまま）
9. **Test users** 画面で **SAVE AND CONTINUE** をクリック
10. **Summary** 画面で **BACK TO DASHBOARD** をクリック

## 2. OAuth 2.0 クライアントIDの作成

1. **APIs & Services** > **Credentials** に移動
2. **CREATE CREDENTIALS** > **OAuth 2.0 Client IDs** をクリック
3. 以下の情報を入力：
   - **Application type**: `Web application`
   - **Name**: `ArgoCD IAP Client`
   - **Authorized redirect URIs**: 
     - `https://argocd.gke-argocd-terraform-tutorial.com/_gcp_gatekeeper/authenticate`
4. **CREATE** をクリック
5. 表示される **Client ID** と **Client Secret** をメモしておく

## 3. Kubernetesシークレットの作成

OAuth Client IDとSecretを使用してKubernetesシークレットを作成：

```bash
kubectl create secret generic oauth-client-secret \
  --from-literal=client_id=YOUR_CLIENT_ID \
  --from-literal=client_secret=YOUR_CLIENT_SECRET \
  -n argocd
```

## 4. Ingressの適用

```bash
kubectl apply -f argocd-manifest/argocd-ingress.yaml
```

## 5. DNS設定の確認

DNSが正しく設定されていることを確認：

```bash
nslookup argocd.gke-argocd-terraform-tutorial.com 8.8.8.8
```

期待される結果: `34.110.224.66` (Ingress IP)

## 6. SSL証明書の確認

SSL証明書がプロビジョニングされるまで10-15分待機：

```bash
kubectl get managedcertificate argocd-ssl-cert -n argocd -o yaml
```

`status.certificateStatus` が `Active` になるまで待機。

## 7. IAP設定の確認

1. [Google Cloud Console](https://console.cloud.google.com/) > **Security** > **Identity-Aware Proxy**
2. **HTTPS Resources** タブで ArgoCD のバックエンドサービスを確認
3. IAP を有効化し、アクセス権限を設定

## 8. アクセステスト

ブラウザで `https://argocd.gke-argocd-terraform-tutorial.com` にアクセス：

1. Google OAuth認証画面が表示される
2. 認証後、ArgoCDのログイン画面が表示される
3. 既存の admin ユーザーでログイン可能

## トラブルシューティング

### SSL証明書が Active にならない場合
- DNS設定が正しいか確認
- ドメインが正しく解決されるか確認
- 10-15分待機してから再確認

### IAP認証が失敗する場合
- OAuth同意画面の設定を確認
- Authorized redirect URIs が正しいか確認
- Kubernetesシークレットが正しく作成されているか確認

### Ingressが作成されない場合
- GKE Ingressコントローラーが有効か確認
- BackendConfigリソースが正しく作成されているか確認 