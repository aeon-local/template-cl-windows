variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "zone" {
  type = string
}

variable "vm_name" {
  type = string
  validation {
    condition     = can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", var.vm_name))
    error_message = "vm_name debe iniciar con letra minúscula y contener solo minúsculas, números y guiones."
  }
}

variable "os_type" {
  type    = string
  default = "Windows-server-2022-dc"
  validation {
    condition     = contains(["Windows-server-2025-dc","Windows-server-2022-dc","Windows-server-2019-dc"], var.os_type)
    error_message = "os_type debe ser Windows-server-2025-dc | Windows-server-2022-dc | Windows-server-2019-dc."
  }
}

variable "processor_tech" {
  type    = string
  default = "e2"
  validation {
    condition     = contains(["n2","e2"], lower(var.processor_tech))
    error_message = "processor_tech debe ser n2 o e2."
  }
}

# vm_type: "n2-standard" | "e2-standard" | "custom"
variable "vm_type" {
  type = string
  validation {
    condition     = contains(["n2-standard","e2-standard","custom"], var.vm_type)
    error_message = "vm_type debe ser n2-standard, e2-standard o custom."
  }
}

variable "vm_cores" {
  type = number
  validation {
    condition     = var.vm_cores >= 2
    error_message = "vm_cores debe ser >= 2 para Windows."
  }
}

variable "vm_memory_gb" {
  type = number
  validation {
    condition     = var.vm_memory_gb >= 4
    error_message = "vm_memory_gb debe ser >= 4 para Windows."
  }
}

variable "disk_type" {
  type = string
  validation {
    condition     = contains(["pd-ssd","pd-balanced","pd-standard"], var.disk_type)
    error_message = "disk_type debe ser pd-ssd | pd-balanced | pd-standard."
  }
}

variable "disk_size_gb" {
  type = number
  validation {
    condition     = var.disk_size_gb >= 50
    error_message = "disk_size_gb debe ser >= 50 GB para Windows."
  }
}

variable "auto_delete_disk" {
  type    = bool
  default = true
}

variable "vpc_network" {
  type = string
}

variable "subnet" {
  type    = string
  default = ""
}

variable "assign_public_ip" {
  type = bool
}

variable "preemptible" {
  type    = bool
  default = false
}

variable "service_account" {
  type    = string
  default = ""
}

variable "deletion_protection" {
  type    = bool
  default = false
}

variable "labels" {
  type    = map(string)
  default = {}
}

variable "network_tags" {
  type    = list(string)
  default = []
}

variable "metadata" {
  type    = map(string)
  default = {}
}