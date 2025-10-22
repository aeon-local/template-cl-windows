variable "project_id" {
  description = "ID del proyecto GCP"
  type        = string
  default     = "jenkins-terraform-demo-472920"
}

variable "region" {
  description = "Región GCP (p.ej. us-central1, southamerica-west1)"
  type        = string
}

variable "zone" {
  description = "Zona GCP (p.ej. us-central1-a, southamerica-west1-b)"
  type        = string
}

variable "vm_name" {
  description = "Nombre de la VM (minúsculas, números y guiones)"
  type        = string
}

variable "processor_tech" {
  description = "Serie de CPU (e2, n2)"
  type        = string
  default     = "e2"
}

variable "vm_type" {
  description = "Familia de tipo de máquina (e2-standard | n2-standard | ...)"
  type        = string
  default     = "e2-standard"
}

variable "vm_cores" {
  description = "Número de vCPUs"
  type        = number
  default     = 2
}

variable "vm_memory_gb" {
  description = "Memoria en GB (solo se usa para custom); para *-standard se ignora"
  type        = number
  default     = 8
}

variable "os_type" {
  description = "Windows server edition (catálogo simplificado)"
  type        = string
  default     = "Windows-server-2022-dc"
  validation {
    condition = contains(["Windows-server-2025-dc","Windows-server-2022-dc","Windows-server-2019-dc"], var.os_type)
    error_message = "os_type debe ser uno de: Windows-server-2025-dc, Windows-server-2022-dc, Windows-server-2019-dc."
  }
}

variable "disk_size_gb" {
  description = "Tamaño del disco de arranque (GB)"
  type        = number
  default     = 100
}

variable "disk_type" {
  description = "Tipo de disco (pd-ssd, pd-balanced, pd-standard)"
  type        = string
  default     = "pd-balanced"
}

variable "infrastructure_type" {
  description = "On-demand o Preemptible"
  type        = string
  default     = "On-demand"
}

variable "vpc_network" {
  description = "Nombre de la red VPC"
  type        = string
  default     = "default"
}

variable "subnet" {
  description = "Nombre de la subred (vacío = subred por defecto de la red/región)"
  type        = string
  default     = ""
}

variable "assign_public_ip" {
  description = "Asignar IP pública"
  type        = bool
  default     = false
}

variable "firewall_rules" {
  description = "Tags para encajar con reglas de firewall (separadas por coma)"
  type        = string
  default     = "allow-rdp,allow-winrm"
}

variable "service_account_email" {
  description = "Cuenta de servicio (vacío = default)"
  type        = string
  default     = ""
}

variable "enable_deletion_protection" {
  description = "Proteger contra borrado"
  type        = bool
  default     = false
}

variable "enable_startup_script" {
  description = "Habilitar script de inicio"
  type        = bool
  default     = false
}

variable "labels" {
  description = "Etiquetas (mapa)"
  type        = map(string)
  default     = {}
}