locals {
  # Mapea tu selección amigable a los nombres reales de familia/proyecto en GCP
  os_catalog = {
    "Windows-server-2025-dc" = { family = "windows-2025-dc", project = "windows-cloud" }
    "Windows-server-2022-dc" = { family = "windows-2022-dc", project = "windows-cloud" }
    "Windows-server-2019-dc" = { family = "windows-2019-dc", project = "windows-cloud" }
  }

  # Construye machine_type. Si usas *-standard: p.ej. e2-standard-2
  # Si alguna vez cambias a custom, pon vm_type con la palabra "custom" y usará e2-custom-<vcpus>-<memMB>
  machine_type = contains(lower(var.vm_type), "custom")
    ? format("%s-custom-%d-%d", lower(var.processor_tech), var.vm_cores, var.vm_memory_gb * 1024)
    : format("%s-%d", lower(var.vm_type), var.vm_cores)

  # Convierte la lista de tags desde el string con comas
  network_tags = [for t in split(",", var.firewall_rules) : trim(t) if trim(t) != ""]
}

# Imagen Windows por familia (siempre coge la más reciente)
data "google_compute_image" "windows" {
  family  = local.os_catalog[var.os_type].family
  project = local.os_catalog[var.os_type].project
}

# Resuelve red/subred
data "google_compute_network" "vpc" {
  name = var.vpc_network
}

# Subred opcional (si no se setea, se usa "auto" por defecto de la red)
data "google_compute_subnetwork" "subnet" {
  count  = var.subnet != "" ? 1 : 0
  name   = var.subnet
  region = var.region
}

resource "google_compute_instance" "vm" {
  name         = var.vm_name
  machine_type = local.machine_type
  zone         = var.zone

  tags = local.network_tags

  # Protección contra borrado
  deletion_protection = var.enable_deletion_protection

  boot_disk {
    initialize_params {
      image = data.google_compute_image.windows.self_link
      size  = var.disk_size_gb
      type  = var.disk_type
    }
    auto_delete = true
  }

  network_interface {
    network    = data.google_compute_network.vpc.self_link
    subnetwork = var.subnet != "" ? data.google_compute_subnetwork.subnet[0].self_link : null

    dynamic "access_config" {
      for_each = var.assign_public_ip ? [1] : []
      content {}
    }
  }

  # Preemptible (máquinas de bajo costo y corta duración)
  scheduling {
    preemptible       = lower(var.infrastructure_type) == "preemptible"
    automatic_restart = !(lower(var.infrastructure_type) == "preemptible")
  }

  # Cuenta de servicio
  service_account {
    email  = var.service_account_email != "" ? var.service_account_email : null
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata = var.enable_startup_script ? {
    # Script de ejemplo mínimo para Windows (habilita WinRM y RDP de forma estándar)
    # Úsalo como base; ajusta a tu hardening.
    "windows-startup-script-ps1" = <<-EOPS
      Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope LocalMachine -Force
      netsh advfirewall firewall add rule name="Allow RDP 3389" dir=in action=allow protocol=TCP localport=3389
      winrm quickconfig -q
    EOPS
  } : {}

  labels = var.labels
}