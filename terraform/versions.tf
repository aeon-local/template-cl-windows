terraform {
  required_version = ">= 1.4.0"

  # Si más adelante quieres guardar el estado en GCS, descomenta y ajusta:
  # backend "gcs" {
  #   bucket = "tfstate-tf"
  #   prefix = "states/gce-vm"
  # }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.45"
    }
  }
}