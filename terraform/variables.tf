variable "project_id"        { type = string }
variable "region"            { type = string }
variable "zone"              { type = string }
variable "vm_name"           { type = string }

# Windows Server a desplegar (coincide con el parámetro OS_TYPE del Jenkinsfile)
variable "os_type" {
  type    = string
  default = "Windows-server-2022-dc"
  validation {
    condition     = contains(["Windows-server-2025-dc","Windows-server-2022-dc","Windows-server-2019-dc"], var.os_type)
    error_message = "os_type debe ser Windows-server-2025-dc | Windows-server-2022-dc | Windows-server-2019-dc."
  }
}

# Máquina
variable "processor_tech" { # n2 | e2
  type    = string
  default = "e2"
  validation {
    condition     = contains(["n2","e2"], lower(var.processor_tech))
    error_message = "processor_tech debe ser n2 o e2."
  }
}

# 'vm_type' puede ser "e2-standard" o "n2-standard" (para tipos estándar) o "custom"
# Tu Jenkinsfile arma "VM_TYPE" como "n2-standard" o "e2-standard". 
# Si quieres custom, pasa literalmente "custom".
variable "vm_type"        { type = string }
variable "vm_cores"       { type = number }
variable "vm_memory_gb"   { type = number }

# Disco
variable "disk_type" {
  type = string
  validation {
    condition     = contains(["pd-ssd","pd-balanced","pd-standard"], var.disk_type)
    error_message = "disk_type debe ser pd-ssd | pd-balanced | pd-standard."
  }
}
variable "disk_size_gb"   { type = number }
variable "auto_delete_disk" {
  type    = bool
  default = true
}

# Red
variable "vpc_network"     { type = string }
variable "subnet"          { type = string, default = "" }
variable "assign_public_ip"{ type = bool }

# Opcionales/extra
variable "preemptible"          { type = bool, default = false }
variable "service_account"      { type = string, default = "" }
variable "deletion_protection"  { type = bool, default = false }
variable "labels"               { type = map(string), default = {} }
variable "network_tags"         { type = list(string), default = [] }
variable "metadata"             { type = map(string), default = {} }