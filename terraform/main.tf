resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "fastapi_vm" {
  name         = "fastapi-vm"
  machine_type = "e2-micro"
  zone         = var.zone

  # Use Container-Optimized OS so guest automatically handles container running
  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable"
      # optionally set disk size
    }
  }

  # attach the VM service account that has artifactregistry.reader role
  service_account {
    email  = var.vm_service_account
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata = {
    # Container declaration to auto-run your artifact image
    "gce-container-declaration" = <<-EOT
      spec:
        containers:
          - name: fastapi
            image: ${var.docker_image}
            stdin: false
            tty: false
            ports:
              - containerPort: 80
        restartPolicy: Always
    EOT
  }
}

output "external_ip" {
  value = google_compute_instance.fastapi_vm.network_interface[0].access_config[0].nat_ip
}