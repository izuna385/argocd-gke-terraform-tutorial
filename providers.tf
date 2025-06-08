terraform {
  required_version = ">= 1.3.0"
  backend "gcs" {
    bucket      = "gcp-iap-test-442622-tf-state"
    prefix      = "terraform/state"
    credentials = "terraform-sa-key.json"
  }
}

provider "google" {
  credentials = file("terraform-sa-key.json")
  project     = var.project_id
  region      = var.region
}

# Kubernetes プロバイダーの設定
data "google_container_cluster" "primary" {
  name     = google_container_cluster.primary.name
  location = google_container_cluster.primary.location
}

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.primary.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.primary.master_auth.0.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = "https://${data.google_container_cluster.primary.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(data.google_container_cluster.primary.master_auth.0.cluster_ca_certificate)
  }
}
