pipeline {
  agent any

  options {
    ansiColor('xterm')
    timestamps()
    timeout(time: 60, unit: 'MINUTES')
    buildDiscarder(logRotator(numToKeepStr: '15'))
  }

  parameters {
    choice(name: 'ACTION', choices: ['apply','destroy'], description: 'apply = crear/actualizar | destroy = eliminar')
    string(name: 'PROJECT_ID', defaultValue: 'linear-time-471113-p5', description: 'GCP Project ID')
    string(name: 'REGION',     defaultValue: 'us-central1',    description: 'Región (p.ej. us-central1)')
    string(name: 'ZONE',       defaultValue: 'us-central1-a',  description: 'Zona (p.ej. us-central1-a)')
    string(name: 'VM_NAME',    defaultValue: 'win-demo',       description: 'Nombre de la VM')

    // Windows – ajusta si usas Linux
    choice(name: 'OS_TYPE', choices: [
      'Windows-server-2025-dc',
      'Windows-server-2022-dc',
      'Windows-server-2019-dc'
    ], description: 'Windows Server Datacenter')

    choice(name: 'DISK_TYPE', choices: ['pd-ssd','pd-balanced','pd-standard'], description: 'Tipo de disco')
    string(name: 'DISK_SIZE_GB', defaultValue: '100', description: 'Tamaño disco (GB, >=50)')
    string(name: 'VPC_NETWORK',  defaultValue: 'default', description: 'VPC')
    string(name: 'SUBNET',       defaultValue: '',         description: 'Subred (vacío = default de la VPC)')
    choice(name: 'PUBLIC_IP',    choices: ['false','true'], description: 'Asignar IP pública')
    string(name: 'WORKSPACE',    defaultValue: '',         description: 'Workspace TF (vacío = vm-<VM_NAME>)')
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
          // ✅ No dependas de $WORKSPACE dentro de sh; usa un alias estable WS
          env.WS = pwd()
          echo "Workspace detectado: ${env.WS}"

          sh """
            set -e
            mkdir -p "\$WS/.bin"
            if [ ! -x "\$WS/.bin/terraform" ]; then
              echo "⬇️ Instalando Terraform 1.6.6 en \$WS/.bin"
              cd "\$WS/.bin"
              curl -sSLo terraform.zip https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip
              unzip -o terraform.zip >/dev/null
              rm -f terraform.zip
              chmod +x terraform
            fi
            "\$WS/.bin/terraform" -version | head -1
          """

          // Añade el bin a PATH para el resto del pipeline
          env.PATH = "${env.WS}/.bin:${env.PATH}"
        }
      }
    }

    stage('Terraform Init + Workspace') {
      steps {
        dir('terraform') {
          withCredentials([file(credentialsId: 'gcp-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
            script {
              def ws = (params.WORKSPACE?.trim())
                        ? params.WORKSPACE.trim()
                        : ("vm-" + params.VM_NAME).toLowerCase().replaceAll('[^a-z0-9-]','-')
              env.TF_WS = ws

              sh """
                set -e
                unset TF_WORKSPACE
                echo "🧭 terraform init…"
                terraform init -input=false -reconfigure
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
              // Genera auto.tfvars para tu módulo
              writeFile file: 'terraform.auto.tfvars', text: """
project_id       = "${params.PROJECT_ID}"
region           = "${params.REGION}"
zone             = "${params.ZONE}"
vm_name          = "${params.VM_NAME}"
os_type          = "${params.OS_TYPE}"
disk_type        = "${params.DISK_TYPE}"
disk_size_gb     = ${params.DISK_SIZE_GB}
vpc_network      = "${params.VPC_NETWORK}"
subnet           = "${params.SUBNET}"
assign_public_ip = ${params.PUBLIC_IP.toBoolean()}
"""

              sh '''
                set -e
                unset TF_WORKSPACE
                echo "📄 terraform.auto.tfvars:"
                cat terraform.auto.tfvars
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
                -var="os_type=${OS_TYPE}" \
                -var="disk_type=${DISK_TYPE}" \
                -var="disk_size_gb=${DISK_SIZE_GB}" \
                -var="vpc_network=${VPC_NETWORK}" \
                -var="subnet=${SUBNET}" \
                -var="assign_public_ip=${PUBLIC_IP}"
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