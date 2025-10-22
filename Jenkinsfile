pipeline {
  agent any

  options {
    timestamps()
    timeout(time: 60, unit: 'MINUTES')
    buildDiscarder(logRotator(numToKeepStr: '15'))
    ansiColor('xterm')
  }

  parameters {
    choice(name: 'ACTION', choices: ['apply','destroy'], description: 'apply = crear/actualizar | destroy = eliminar')
    // -------- Proyecto / ubicación ----------
    string(name: 'PROJECT_ID', defaultValue: 'jenkins-terraform-demo-472920', description: 'GCP Project ID')
    string(name: 'REGION',     defaultValue: 'us-central1',                description: 'Región (p.ej. us-central1, southamerica-west1)')
    string(name: 'ZONE',       defaultValue: 'us-central1-a',              description: 'Zona (p.ej. us-central1-a)')
    string(name: 'WORKSPACE',  defaultValue: '',                            description: 'Workspace TF (vacío = vm-<VM_NAME>)')

    // -------- VM ----------
    string(name: 'VM_NAME',    defaultValue: 'win-demo',                    description: 'Nombre VM (minúsculas y guiones)')
    choice(name: 'PROCESSOR_TECH', choices: ['e2','n2'],                    description: 'Serie (e2 / n2)')
    choice(name: 'VM_TYPE',       choices: ['e2-standard','n2-standard'],   description: 'Familia (standard/custom)')
    string(name: 'VM_CORES',      defaultValue: '2',                        description: 'vCPUs')
    string(name: 'VM_MEMORY_GB',  defaultValue: '8',                        description: 'Memoria (GB) (solo custom)')

    // -------- Imagen Windows ----------
    choice(name: 'OS_TYPE', choices: [
      'Windows-server-2025-dc',
      'Windows-server-2022-dc',
      'Windows-server-2019-dc'
    ], description: 'Edición Windows Server Datacenter')

    // -------- Disco ----------
    string(name: 'DISK_SIZE_GB', defaultValue: '100', description: 'Tamaño disco (GB, >=50)')
    choice(name: 'DISK_TYPE', choices: ['pd-ssd','pd-balanced','pd-standard'], description: 'Tipo de disco')

    // -------- Red ----------
    string(name: 'VPC_NETWORK', defaultValue: 'default', description: 'VPC')
    string(name: 'SUBNET',      defaultValue: '',         description: 'Subred (vacío = predeterminada)')
    choice(name: 'PUBLIC_IP',   choices: ['false','true'], description: 'Asignar IP pública')

    // -------- Otros ----------
    string(name: 'FIREWALL_RULES', defaultValue: 'allow-rdp,allow-winrm', description: 'Tags para reglas de firewall (comas)')
    string(name: 'SERVICE_ACCOUNT', defaultValue: '', description: 'SA para la VM (vacío = default)')
    choice(name: 'ENABLE_DELETION_PROTECTION', choices: ['false','true'], description: 'Proteger contra borrado')
    choice(name: 'ENABLE_STARTUP_SCRIPT', choices: ['true','false'], description: 'Habilitar script de inicio mínimo')
  }

  environment {
    TF_IN_AUTOMATION = 'true'
    TF_INPUT         = 'false'
  }

  stages {

    stage('Auth GCP') {
      steps {
        withCredentials([file(credentialsId: 'gcp-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
          sh '''
            set -e
            gcloud auth activate-service-account --key-file="$GOOGLE_APPLICATION_CREDENTIALS"
            gcloud config set project "${PROJECT_ID}" >/dev/null
            echo "✅ GCP autenticado. Proyecto: ${PROJECT_ID}"
            gcloud --version
          '''
        }
      }
    }

    stage('Setup Terraform') {
      steps {
        script {
          sh '''
            set -e
            mkdir -p "$WORKSPACE/.bin"
            if ! command -v terraform >/dev/null 2>&1; then
              echo "⬇️ Instalando Terraform 1.6.6"
              cd "$WORKSPACE/.bin"
              curl -sSLo terraform.zip https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip
              unzip -o terraform.zip >/dev/null
              rm -f terraform.zip
              chmod +x terraform
            fi
            echo "✅ Terraform: $("$WORKSPACE/.bin/terraform" -version | head -1)"
          '''
          // agrega terraform al PATH del resto de etapas
          env.PATH = "${env.WORKSPACE}/.bin:${env.PATH}"
        }
      }
    }

    stage('Terraform Init + Workspace') {
      steps {
        dir('terraform') {
          withCredentials([file(credentialsId: 'gcp-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
            script {
              // Workspace destino
              def ws = (params.WORKSPACE?.trim()) ? params.WORKSPACE.trim()
                                                  : ("vm-" + params.VM_NAME).toLowerCase().replaceAll('[^a-z0-9-]','-')
              env.TF_WS = ws

              sh """
                set -e
                unset TF_WORKSPACE
                echo "🧭 terraform init…"
                terraform init -input=false -reconfigure
                # crea o selecciona el workspace
                terraform workspace select "${env.TF_WS}" >/dev/null 2>&1 || terraform workspace new "${env.TF_WS}"
                echo "✅ Workspace activo: \$(terraform workspace show)"
              """
            }
          }
        }
      }
    }

    stage('Apply (create/update)') {
      when { expression { params.ACTION == 'apply' } }
      steps {
        dir('terraform') {
          withCredentials([file(credentialsId: 'gcp-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
            script {
              // Tipos y booleanos para tfvars
              def vcpus = params.VM_CORES as Integer
              def memGb = params.VM_MEMORY_GB as Integer
              def diskGb = params.DISK_SIZE_GB as Integer
              def assignPub = params.PUBLIC_IP.toBoolean()
              def delProt   = params.ENABLE_DELETION_PROTECTION.toBoolean()
              def startup   = params.ENABLE_STARTUP_SCRIPT.toBoolean()

              writeFile file: 'terraform.auto.tfvars', text: """
project_id            = "${params.PROJECT_ID}"
region                = "${params.REGION}"
zone                  = "${params.ZONE}"
vm_name               = "${params.VM_NAME}"
processor_tech        = "${params.PROCESSOR_TECH}"
vm_type               = "${params.VM_TYPE}"
vm_cores              = ${vcpus}
vm_memory_gb          = ${memGb}
os_type               = "${params.OS_TYPE}"
disk_size_gb          = ${diskGb}
disk_type             = "${params.DISK_TYPE}"
infrastructure_type   = "On-demand"
vpc_network           = "${params.VPC_NETWORK}"
subnet                = "${params.SUBNET}"
assign_public_ip      = ${assignPub}
firewall_rules        = "${params.FIREWALL_RULES}"
service_account_email = "${params.SERVICE_ACCOUNT}"
enable_deletion_protection = ${delProt}
enable_startup_script = ${startup}
"""

              sh '''
                set -e
                unset TF_WORKSPACE
                echo "📄 terraform.auto.tfvars:"
                sed 's/\\(account\\|password\\|token\\)=.*/\\1=***HIDDEN***/' terraform.auto.tfvars || true
                terraform plan -out=tfplan
                terraform apply -auto-approve tfplan
              '''
            }
          }
        }
      }
    }

    stage('Destroy') {
      when { expression { params.ACTION == 'destroy' } }
      steps {
        dir('terraform') {
          withCredentials([file(credentialsId: 'gcp-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
            sh '''
              set -e
              unset TF_WORKSPACE
              terraform destroy -auto-approve \
                -var="project_id=${PROJECT_ID}" \
                -var="region=${REGION}" \
                -var="zone=${ZONE}" \
                -var="vm_name=${VM_NAME}" \
                -var="processor_tech=${PROCESSOR_TECH}" \
                -var="vm_type=${VM_TYPE}" \
                -var="vm_cores=${VM_CORES}" \
                -var="vm_memory_gb=${VM_MEMORY_GB}" \
                -var="os_type=${OS_TYPE}" \
                -var="disk_size_gb=${DISK_SIZE_GB}" \
                -var="disk_type=${DISK_TYPE}" \
                -var="infrastructure_type=On-demand" \
                -var="vpc_network=${VPC_NETWORK}" \
                -var="subnet=${SUBNET}" \
                -var="assign_public_ip=${PUBLIC_IP}" \
                -var="firewall_rules=${FIREWALL_RULES}" \
                -var="service_account_email=${SERVICE_ACCOUNT}" \
                -var="enable_deletion_protection=${ENABLE_DELETION_PROTECTION}" \
                -var="enable_startup_script=${ENABLE_STARTUP_SCRIPT}"
              echo "✅ Destroy completado"
            '''
          }
        }
      }
    }
  }

  post {
    success { echo "✅ Pipeline OK" }
    failure { echo "❌ Pipeline falló" }
  }
}