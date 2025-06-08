
## tf用サービスアカウント作成

```bash
$ gcloud iam service-accounts create terraform-sa --display-name="Terraform Service Account" --description="Service account for Terraform operations"
```

以降は, TF_SERVICE_ACCOUNT.mdを参照

## バケット保存用の権限付与, バケット作成
```
$ PROJECT_ID=$(gcloud config get-value project) && gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:terraform-sa@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/storage.admin"

# バケットのバージョニング有効化
$ PROJECT_ID=$(gcloud config get-value project) && gsutil mb -p $PROJECT_ID gs://$PROJECT_ID-tf-state
```

# terraform plan

<details>

<summary>plan, apply</summary>

```bash
➜  argocd-gke-terraform-tutorial git:(main) ✗ terraform plan
Acquiring state lock. This may take a few moments...
data.google_client_config.default: Reading...
data.google_client_config.default: Read complete after 0s [id=projects/"gcp-iap-test-442622"/regions/"asia-northeast1"/zones/<null>]

Terraform used the selected providers to generate the following execution plan. Resource actions are
indicated with the following symbols:
  + create
 <= read (data resources)

Terraform will perform the following actions:

  # data.google_container_cluster.primary will be read during apply
  # (depends on a resource or a module with changes pending)
 <= data "google_container_cluster" "primary" {
      + addons_config                            = (known after apply)
      + allow_net_admin                          = (known after apply)
      + authenticator_groups_config              = (known after apply)
      + binary_authorization                     = (known after apply)
      + cluster_autoscaling                      = (known after apply)
      + cluster_ipv4_cidr                        = (known after apply)
      + confidential_nodes                       = (known after apply)
      + cost_management_config                   = (known after apply)
      + database_encryption                      = (known after apply)
      + datapath_provider                        = (known after apply)
      + default_max_pods_per_node                = (known after apply)
      + default_snat_status                      = (known after apply)
      + deletion_protection                      = (known after apply)
      + description                              = (known after apply)
      + dns_config                               = (known after apply)
      + enable_autopilot                         = (known after apply)
      + enable_cilium_clusterwide_network_policy = (known after apply)
      + enable_intranode_visibility              = (known after apply)
      + enable_k8s_beta_apis                     = (known after apply)
      + enable_kubernetes_alpha                  = (known after apply)
      + enable_l4_ilb_subsetting                 = (known after apply)
      + enable_legacy_abac                       = (known after apply)
      + enable_multi_networking                  = (known after apply)
      + enable_shielded_nodes                    = (known after apply)
      + enable_tpu                               = (known after apply)
      + endpoint                                 = (known after apply)
      + fleet                                    = (known after apply)
      + gateway_api_config                       = (known after apply)
      + id                                       = (known after apply)
      + identity_service_config                  = (known after apply)
      + initial_node_count                       = (known after apply)
      + ip_allocation_policy                     = (known after apply)
      + label_fingerprint                        = (known after apply)
      + location                                 = "asia-northeast1"
      + logging_config                           = (known after apply)
      + logging_service                          = (known after apply)
      + maintenance_policy                       = (known after apply)
      + master_auth                              = (known after apply)
      + master_authorized_networks_config        = (known after apply)
      + master_version                           = (known after apply)
      + mesh_certificates                        = (known after apply)
      + min_master_version                       = (known after apply)
      + monitoring_config                        = (known after apply)
      + monitoring_service                       = (known after apply)
      + name                                     = "argocd-gke-cluster"
      + network                                  = (known after apply)
      + network_policy                           = (known after apply)
      + networking_mode                          = (known after apply)
      + node_config                              = (known after apply)
      + node_locations                           = (known after apply)
      + node_pool                                = (known after apply)
      + node_pool_auto_config                    = (known after apply)
      + node_pool_defaults                       = (known after apply)
      + node_version                             = (known after apply)
      + notification_config                      = (known after apply)
      + operation                                = (known after apply)
      + private_cluster_config                   = (known after apply)
      + private_ipv6_google_access               = (known after apply)
      + release_channel                          = (known after apply)
      + remove_default_node_pool                 = (known after apply)
      + resource_labels                          = (known after apply)
      + resource_usage_export_config             = (known after apply)
      + security_posture_config                  = (known after apply)
      + self_link                                = (known after apply)
      + service_external_ips_config              = (known after apply)
      + services_ipv4_cidr                       = (known after apply)
      + subnetwork                               = (known after apply)
      + tpu_ipv4_cidr_block                      = (known after apply)
      + vertical_pod_autoscaling                 = (known after apply)
      + workload_identity_config                 = (known after apply)
    }

  # google_compute_global_address.argocd_ip will be created
  + resource "google_compute_global_address" "argocd_ip" {
      + address            = (known after apply)
      + creation_timestamp = (known after apply)
      + description        = "Static IP for ArgoCD ingress"
      + effective_labels   = (known after apply)
      + id                 = (known after apply)
      + label_fingerprint  = (known after apply)
      + name               = "argocd-static-ip"
      + prefix_length      = (known after apply)
      + project            = "gcp-iap-test-442622"
      + self_link          = (known after apply)
      + terraform_labels   = (known after apply)
    }

  # google_container_cluster.primary will be created
  + resource "google_container_cluster" "primary" {
      + cluster_ipv4_cidr                        = (known after apply)
      + datapath_provider                        = (known after apply)
      + default_max_pods_per_node                = (known after apply)
      + deletion_protection                      = true
      + enable_cilium_clusterwide_network_policy = false
      + enable_intranode_visibility              = (known after apply)
      + enable_kubernetes_alpha                  = false
      + enable_l4_ilb_subsetting                 = false
      + enable_legacy_abac                       = false
      + enable_multi_networking                  = false
      + enable_shielded_nodes                    = true
      + endpoint                                 = (known after apply)
      + id                                       = (known after apply)
      + initial_node_count                       = 1
      + label_fingerprint                        = (known after apply)
      + location                                 = "asia-northeast1"
      + logging_service                          = (known after apply)
      + master_version                           = (known after apply)
      + monitoring_service                       = (known after apply)
      + name                                     = "argocd-gke-cluster"
      + network                                  = "default"
      + networking_mode                          = (known after apply)
      + node_locations                           = (known after apply)
      + node_version                             = (known after apply)
      + operation                                = (known after apply)
      + private_ipv6_google_access               = (known after apply)
      + project                                  = (known after apply)
      + remove_default_node_pool                 = true
      + self_link                                = (known after apply)
      + services_ipv4_cidr                       = (known after apply)
      + subnetwork                               = "default"
      + tpu_ipv4_cidr_block                      = (known after apply)

      + addons_config (known after apply)

      + authenticator_groups_config (known after apply)

      + cluster_autoscaling (known after apply)

      + confidential_nodes (known after apply)

      + cost_management_config (known after apply)

      + database_encryption (known after apply)

      + default_snat_status (known after apply)

      + gateway_api_config (known after apply)

      + identity_service_config (known after apply)

      + ip_allocation_policy (known after apply)

      + logging_config (known after apply)

      + master_auth (known after apply)

      + master_authorized_networks_config (known after apply)

      + mesh_certificates (known after apply)

      + monitoring_config (known after apply)

      + node_config (known after apply)

      + node_pool (known after apply)

      + node_pool_auto_config (known after apply)

      + node_pool_defaults (known after apply)

      + notification_config (known after apply)

      + release_channel {
          + channel = "REGULAR"
        }

      + security_posture_config (known after apply)

      + service_external_ips_config (known after apply)

      + vertical_pod_autoscaling (known after apply)

      + workload_identity_config {
          + workload_pool = "gcp-iap-test-442622.svc.id.goog"
        }
    }

  # google_container_node_pool.primary_nodes will be created
  + resource "google_container_node_pool" "primary_nodes" {
      + cluster                     = "argocd-gke-cluster"
      + id                          = (known after apply)
      + initial_node_count          = (known after apply)
      + instance_group_urls         = (known after apply)
      + location                    = "asia-northeast1"
      + managed_instance_group_urls = (known after apply)
      + max_pods_per_node           = (known after apply)
      + name                        = "argocd-gke-cluster-node-pool"
      + name_prefix                 = (known after apply)
      + node_count                  = 2
      + node_locations              = (known after apply)
      + operation                   = (known after apply)
      + project                     = "gcp-iap-test-442622"
      + version                     = (known after apply)

      + management (known after apply)

      + network_config (known after apply)

      + node_config {
          + disk_size_gb      = (known after apply)
          + disk_type         = (known after apply)
          + effective_taints  = (known after apply)
          + guest_accelerator = (known after apply)
          + image_type        = (known after apply)
          + labels            = (known after apply)
          + local_ssd_count   = (known after apply)
          + logging_variant   = (known after apply)
          + machine_type      = "e2-medium"
          + metadata          = (known after apply)
          + min_cpu_platform  = (known after apply)
          + oauth_scopes      = [
              + "https://www.googleapis.com/auth/cloud-platform",
            ]
          + preemptible       = true
          + service_account   = (known after apply)
          + spot              = false

          + confidential_nodes (known after apply)

          + gcfs_config (known after apply)

          + kubelet_config (known after apply)

          + shielded_instance_config (known after apply)

          + workload_metadata_config {
              + mode = "GKE_METADATA"
            }
        }

      + upgrade_settings (known after apply)
    }

  # google_dns_managed_zone.argocd_zone will be created
  + resource "google_dns_managed_zone" "argocd_zone" {
      + creation_time    = (known after apply)
      + description      = "Zone for ArgoCD"
      + dns_name         = "gke-argocd-terraform-tutorial.com."
      + effective_labels = (known after apply)
      + force_destroy    = false
      + id               = (known after apply)
      + managed_zone_id  = (known after apply)
      + name             = "argocd-zone"
      + name_servers     = (known after apply)
      + project          = "gcp-iap-test-442622"
      + terraform_labels = (known after apply)
      + visibility       = "public"

      + cloud_logging_config (known after apply)
    }

  # google_dns_record_set.argocd_a_record will be created
  + resource "google_dns_record_set" "argocd_a_record" {
      + id           = (known after apply)
      + managed_zone = "argocd-zone"
      + name         = "argocd.gke-argocd-terraform-tutorial.com."
      + project      = "gcp-iap-test-442622"
      + rrdatas      = (known after apply)
      + ttl          = 300
      + type         = "A"
    }

  # google_service_account.gke_node_sa will be created
  + resource "google_service_account" "gke_node_sa" {
      + account_id   = "argocd-gke-cluster-node-sa"
      + disabled     = false
      + display_name = "GKE Node Service Account"
      + email        = (known after apply)
      + id           = (known after apply)
      + member       = (known after apply)
      + name         = (known after apply)
      + project      = "gcp-iap-test-442622"
      + unique_id    = (known after apply)
    }

  # google_storage_bucket.tf_state will be created
  + resource "google_storage_bucket" "tf_state" {
      + effective_labels            = (known after apply)
      + force_destroy               = false
      + id                          = (known after apply)
      + location                    = "ASIA-NORTHEAST1"
      + name                        = "gcp-iap-test-442622-tf-state"
      + project                     = (known after apply)
      + project_number              = (known after apply)
      + public_access_prevention    = (known after apply)
      + rpo                         = (known after apply)
      + self_link                   = (known after apply)
      + storage_class               = "STANDARD"
      + terraform_labels            = (known after apply)
      + uniform_bucket_level_access = true
      + url                         = (known after apply)

      + soft_delete_policy (known after apply)

      + versioning {
          + enabled = true
        }

      + website (known after apply)
    }

Plan: 7 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + argocd_domain          = "argocd.gke-argocd-terraform-tutorial.com"
  + argocd_static_ip       = (known after apply)
  + cluster_endpoint       = (sensitive value)
  + cluster_location       = "asia-northeast1"
  + cluster_name           = "argocd-gke-cluster"
  + dns_name_servers       = (known after apply)
  + kubectl_config_command = "gcloud container clusters get-credentials argocd-gke-cluster --region asia-northeast1 --project gcp-iap-test-442622"
  + tf_state_bucket        = "gs://gcp-iap-test-442622-tf-state"

```


</details>

## ArgoCD, ArgoCD-image-updater 導入
```bash
$ helm install argocd argo/argo-cd -n argocd \
    --set server.service.type=LoadBalancer
$ helm install argocd-image-updater argo/argocd-image-updater --namespace argocd

```

## 参考文献
https://medium.com/@tharukam/configuring-argo-cd-on-gke-with-ingress-iap-and-google-oauth-for-rbac-a746fd009b78
https://zenn.dev/cloud_ace/articles/argocd_on_gke
