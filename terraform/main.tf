#############################################
# Locals
#############################################
locals {
  # Mapa OS → familia/proyecto (imágenes oficiales Windows)
  os_map = {
    "Windows-server-2025-dc" = { family = "windows-2025", project = "windows-cloud" }
    "Windows-server-2022-dc" = { family = "windows-2022", project = "windows-cloud" }
    "Windows-server-2019-dc" = { family = "windows-2019", project = "windows-cloud" }
  }

  selected_os = lookup(local.os_map, var.os_type, { family = "windows-2022", project = "windows-cloud" })

  # Si vm_type == "custom" → <serie>-custom-<vcpus>-<memMB>; si no → <serie>-standard-<vcpus>
  machine_type = var.vm_type == "custom"
    ? format("%s-custom-%d-%d", lower(var.processor_tech), var.vm_cores, var.vm_memory_gb * 1024)
    : format("%s-standard-%d", lower(var.processor_tech), var.vm_cores)
}

#############################################
# Imagen
#############################################
data "google_compute_image" "os" {
  family  = local.selected_os.family
  project = local.selected_os.project
}

#############################################
# Instancia
#############################################
resource "google_compute_instance" "vm" {
  name         = var.vm_name
  machine_type = local.machine_type
  zone         = var.zone

  deletion_protection = var.deletion_protection
  labels              = var.labels
  tags                = var.network_tags
  metadata            = var.metadata

  boot_disk {
    auto_delete = var.auto_delete_disk
    initialize_params {
      image = data.google_compute_image.os.self_link
      type  = var.disk_type
      size  = var.disk_size_gb
    }
  }

  network_interface {
    network    = var.vpc_network
    subnetwork = var.subnet != "" ? var.subnet : null

    dynamic "access_config" {
      for_each = var.assign_public_ip ? [1] : []
      content {}
    }
  }

  scheduling {
    preemptible        = var.preemptible
    automatic_restart  = var.preemptible ? false : true
    provisioning_model = var.preemptible ? "SPOT" : "STANDARD"
  }

  # Solo agregar bloque si se especifica una SA distinta de la por defecto
  dynamic "service_account" {
    for_each = var.service_account != "" ? [1] : []
    content {
      email  = var.service_account
      scopes = ["https://www.googleapis.com/auth/cloud-platform"]
    }
  }
