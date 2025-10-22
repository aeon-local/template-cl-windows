provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
  # Terraform tomará las credenciales del entorno:
  # export GOOGLE_APPLICATION_CREDENTIALS=/ruta/al/gcp-sa-plataforma.json
}