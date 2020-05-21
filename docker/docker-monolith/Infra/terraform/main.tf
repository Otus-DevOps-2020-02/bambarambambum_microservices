provider "google" {
  version = "~> 2.15"
  project = var.project
  region  = var.region
}
// SSH Keys
resource "google_compute_project_metadata_item" "ssh-keys" {
  key   = "ssh-keys"
  value = var.public_key
}
// Instance
resource "google_compute_instance" "app" {
  count        = 2
  name         = "reddit-app-${count.index + 1}"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["reddit-app-docker"]
  boot_disk {
    initialize_params { image = var.app_disk_image }
  }
  network_interface {
    network = "default"
    access_config { }
  }
  metadata = {
    ssh-keys = "mikh_androsov:${file(var.public_key_path)}"
  }
  connection {
    type        = "ssh"
    host        = self.network_interface[0].access_config[0].nat_ip
    user        = "mikh_androsov"
    agent       = false
    private_key = file(var.private_key_path)
  }
}
// Firewall rules
resource "google_compute_firewall" "firewall_puma" {
  name    = "allow-puma-default"
  network = "default"
  allow {
    protocol = "tcp"
    ports    = ["9292"]
  }
  source_ranges = var.source_ranges
  target_tags   = ["reddit-app-docker"]
}
