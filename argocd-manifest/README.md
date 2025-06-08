## fastapi-app manifest

### apply
```bash
$ kubectl apply -f fastapi-app.yaml -n argocd
> application.argoproj.io/fastapi-app created
```

### argocd status
```bash
$ argocd login 34.84.10.93 --insecure --username admin --password abcd
$ argocd app sync fastapi-app 
```

### app status
```bash
# IP取得
$ kubectl get svc fastapi-app -n fastapi -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
$ kubectl get svc -n fastapi -o wide
```

```
NAME                 TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)        AGE    SELECTOR
fastapi-app          LoadBalancer   34.118.227.230   34.146.118.150   80:30737/TCP   39s    app=fastapi-app
kubernetes           ClusterIP      34.118.224.1     <none>           443/TCP        143m   <none>
sample-app-service   ClusterIP      34.118.225.44    <none>           80/TCP         35m    app=sample-app
```


### 注意点
GKE 側から Artifact Registry にpull可能とするために
以下の設定が必要

```bash
$ gcloud projects add-iam-policy-binding gcp-iap-test-442622 --member="serviceAccount:$(gcloud container clusters describe argocd-gke-cluster1 --region=asia-northeast1 --format='value(nodeConfig.serviceAccount)')" --role="roles/artifactregistry.reader"
```

