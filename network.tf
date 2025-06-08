resource "google_compute_network" "gke_network" {
  name                    = "gke-network"
  auto_create_subnetworks = true  # 自動で各リージョンにサブネット作成
}