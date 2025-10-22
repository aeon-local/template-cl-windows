pipeline {
    agent any

    environment {
        // Configuración predeterminada del país y sistema operativo
        PAIS = 'CL'
        SISTEMA_OPERATIVO_BASE = 'Windows'
        
        // Configuración de snapshots
        SNAPSHOT_ENABLED = 'true'
    }

    options {
        timeout(time: 2, unit: 'HOURS')
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    parameters {
        // ========================================
        // CONFIGURACIÓN DE PROYECTO GCP
        // ========================================
        string(
            name: 'PROYECT_ID', 
            defaultValue: '', 
            description: 'ID del proyecto en Google Cloud Platform'
        )
        string(
            name: 'REGION', 
            defaultValue: 'us-central1', 
            description: 'Región de GCP donde se desplegará la VM (ejemplo: us-central1, southamerica-west1)'
        )
        string(
            name: 'ZONE', 
            defaultValue: 'us-central1-a', 
            description: 'Zona de disponibilidad específica (ejemplo: us-central1-a, southamerica-west1-b)'
        )
        choice(
            name: 'ENVIRONMENT', 
            choices: ['1-Desarrollo', '2-Pre productivo (PP)', '3-Producción'], 
            description: 'Ambiente de despliegue de la infraestructura'
        )
        
        // ========================================
        // CONFIGURACIÓN DE LA MÁQUINA VIRTUAL
        // ========================================
        string(
            name: 'VM_NAME', 
            defaultValue: '', 
            description: 'Nombre único para la máquina virtual (debe cumplir con convenciones de nomenclatura de GCP)'
        )
        choice(
            name: 'PROCESSOR_TECH', 
            choices: ['n2', 'e2'], 
            description: 'Tecnología de procesador (N2: Intel Cascade Lake o Ice Lake, E2: Última generación optimizada para costos)'
        )
        choice(
            name: 'VM_TYPE', 
            choices: ['n2-standard', 'e2-standard'], 
            description: 'Familia de tipo de máquina virtual'
        )
        string(
            name: 'VM_CORES', 
            defaultValue: '2', 
            description: 'Número de vCPUs para la máquina virtual (ejemplo: 2, 4, 8)'
        )
        string(
            name: 'VM_MEMORY', 
            defaultValue: '8', 
            description: 'Memoria RAM en GB (ejemplo: 4, 8, 16, 32)'
        )
        
        // ========================================
        // CONFIGURACIÓN DEL SISTEMA OPERATIVO
        // ========================================
        choice(
            name: 'OS_TYPE', 
            choices: ['Windows-server-2025-dc', 'Windows-server-2022-dc', 'Windows-server-2019-dc'], 
            description: 'Versión del sistema operativo Windows Server Datacenter'
        )
        
        // ========================================
        // CONFIGURACIÓN DE ALMACENAMIENTO
        // ========================================
        string(
            name: 'DISK_SIZE', 
            defaultValue: '100', 
            description: 'Tamaño del disco persistente en GB (mínimo 50 GB para Windows Server)'
        )
        choice(
            name: 'DISK_TYPE', 
            choices: ['pd-ssd', 'pd-balanced', 'pd-standard'], 
            description: 'Tipo de disco (SSD: Mayor rendimiento, Balanced: Equilibrio, Standard: Económico)'
        )
        
        // ========================================
        // CONFIGURACIÓN DE INFRAESTRUCTURA
        // ========================================
        choice(
            name: 'INFRAESTRUCTURE_TYPE', 
            choices: ['On-demand', 'Preemptible'], 
            description: 'Tipo de infraestructura (On-demand: Siempre disponible, Preemptible: Hasta 80% más económico pero puede interrumpirse)'
        )
        
        // ========================================
        // CONFIGURACIÓN DE RED
        // ========================================
        string(
            name: 'VPC_NETWORK', 
            defaultValue: 'default', 
            description: 'Nombre de la red VPC (Virtual Private Cloud)'
        )
        string(
            name: 'SUBNET', 
            defaultValue: '', 
            description: 'Nombre de la subred dentro de la VPC'
        )
        string(
            name: 'NETWORK_SEGMENT', 
            defaultValue: '', 
            description: 'Segmento de red CIDR (ejemplo: 10.0.1.0/24, 192.168.1.0/24)'
        )
        string(
            name: 'INTERFACE', 
            defaultValue: 'nic0', 
            description: 'Nombre de la interfaz de red principal'
        )
        choice(
            name: 'PRIVATE_IP', 
            choices: ['true', 'false'], 
            description: 'Asignar dirección IP privada estática'
        )
        choice(
            name: 'PUBLIC_IP', 
            choices: ['false', 'true'], 
            description: 'Asignar dirección IP pública (externa) a la VM'
        )
        
        // ========================================
        // CONFIGURACIÓN DE SEGURIDAD
        // ========================================
        string(
            name: 'FIREWALL_RULES', 
            defaultValue: 'allow-rdp,allow-winrm', 
            description: 'Reglas de firewall separadas por comas (ejemplo: allow-rdp,allow-winrm,allow-https)'
        )
        string(
            name: 'SERVICE_ACCOUNT', 
            defaultValue: '', 
            description: 'Cuenta de servicio para la VM (dejar vacío para usar la cuenta predeterminada)'
        )
        
        // ========================================
        // ETIQUETAS Y METADATOS
        // ========================================
        string(
            name: 'LABEL', 
            defaultValue: '', 
            description: 'Etiquetas personalizadas para la VM en formato key=value (ejemplo: app=web,tier=frontend)'
        )
        
        // ========================================
        // CONFIGURACIÓN DE SCRIPTS Y ARRANQUE
        // ========================================
        choice(
            name: 'ENABLE_STARTUP_SCRIPT', 
            choices: ['false', 'true'], 
            description: 'Habilitar script de inicio personalizado'
        )
        
        // ========================================
        // OPCIONES DE GESTIÓN
        // ========================================
        choice(
            name: 'ENABLE_DELETION_PROTECTION', 
            choices: ['false', 'true'], 
            description: 'Proteger la VM contra eliminación accidental'
        )
        choice(
            name: 'CHECK_DELETE', 
            choices: ['false', 'true'], 
            description: 'Solicitar confirmación antes de eliminar recursos'
        )
        choice(
            name: 'AUTO_DELETE_DISK', 
            choices: ['true', 'false'], 
            description: 'Eliminar automáticamente el disco al eliminar la VM'
        )
    }

    stages {
        stage('Validación de Parámetros') {
            steps {
                script {
                    echo '================================================'
                    echo '         VALIDACIÓN DE PARÁMETROS              '
                    echo '================================================'
                    
                    // Validaciones críticas
                    def errores = []
                    
                    if (!params.PROYECT_ID?.trim()) {
                        errores.add('PROJECT_ID es obligatorio')
                    }
                    if (!params.VM_NAME?.trim()) {
                        errores.add('VM_NAME es obligatorio')
                    }
                    if (!params.REGION?.trim()) {
                        errores.add('REGION es obligatoria')
                    }
                    if (!params.ZONE?.trim()) {
                        errores.add('ZONE es obligatoria')
                    }
                    
                    // Validar tamaño de disco
                    def diskSize = params.DISK_SIZE?.trim() ? params.DISK_SIZE.toInteger() : 0
                    if (diskSize < 50) {
                        errores.add('DISK_SIZE debe ser al menos 50 GB para Windows Server')
                    }
                    
                    // Validar nombre de VM
                    if (params.VM_NAME && !params.VM_NAME.matches('^[a-z][-a-z0-9]{0,61}[a-z0-9]$')) {
                        errores.add('VM_NAME debe comenzar con letra minúscula, contener solo letras, números y guiones')
                    }
                    
                    if (errores.size() > 0) {
                        echo 'Errores de validación:'
                        errores.each { echo "  - ${it}" }
                        error('Validación de parámetros fallida')
                    }
                    
                    echo 'Validación de parámetros completada exitosamente'
                }
            }
        }

        stage('Mostrar Configuración') {
            steps {
                script {
                    // Calcular valores derivados
                    def snapshotSO = "${params.VM_NAME}-os-snapshot"
                    def snapshotDisco = "${params.VM_NAME}-disk-snapshot"
                    def labelOculto = "${params.ENVIRONMENT}-Env"
                    def startupScript = "${params.VM_NAME}-startup-script"
                    def tipoMaquinaCompleto = "${params.VM_TYPE}-${params.VM_CORES}-${params.VM_MEMORY * 1024}"
                    
                    // Configuraciones organizadas
                    def configPredeterminada = [
                        'País': env.PAIS,
                        'Sistema Operativo Base': env.SISTEMA_OPERATIVO_BASE,
                        'Snapshots Habilitados': env.SNAPSHOT_ENABLED,
                        'Snapshot del SO': snapshotSO,
                        'Snapshot del Disco': snapshotDisco,
                        'Etiqueta de Ambiente': labelOculto,
                        'Script de Inicio': startupScript
                    ]
                    
                    def configProyecto = [
                        'ID de Proyecto': params.PROYECT_ID,
                        'Región': params.REGION,
                        'Zona': params.ZONE,
                        'Ambiente': params.ENVIRONMENT
                    ]
                    
                    def configVM = [
                        'Nombre de VM': params.VM_NAME,
                        'Tecnología de Procesador': params.PROCESSOR_TECH,
                        'Tipo de Máquina': tipoMaquinaCompleto,
                        'vCPUs': params.VM_CORES,
                        'Memoria RAM': "${params.VM_MEMORY} GB",
                        'Sistema Operativo': params.OS_TYPE,
                        'Tipo de Infraestructura': params.INFRAESTRUCTURE_TYPE
                    ]
                    
                    def configAlmacenamiento = [
                        'Tamaño del Disco': "${params.DISK_SIZE} GB",
                        'Tipo de Disco': params.DISK_TYPE,
                        'Eliminación Automática': params.AUTO_DELETE_DISK
                    ]
                    
                    def configRed = [
                        'Red VPC': params.VPC_NETWORK,
                        'Subred': params.SUBNET ?: 'Predeterminada',
                        'Segmento de Red': params.NETWORK_SEGMENT ?: 'No especificado',
                        'Interfaz': params.INTERFACE,
                        'IP Privada': params.PRIVATE_IP,
                        'IP Pública': params.PUBLIC_IP
                    ]
                    
                    def configSeguridad = [
                        'Reglas de Firewall': params.FIREWALL_RULES,
                        'Cuenta de Servicio': params.SERVICE_ACCOUNT ?: 'Predeterminada',
                        'Protección contra Eliminación': params.ENABLE_DELETION_PROTECTION,
                        'Script de Inicio': params.ENABLE_STARTUP_SCRIPT
                    ]
                    
                    def configGestion = [
                        'Etiquetas Personalizadas': params.LABEL ?: 'Ninguna',
                        'Verificación de Eliminación': params.CHECK_DELETE
                    ]
                    
                    // Imprimir todas las configuraciones organizadas
                    echo '\n================================================'
                    echo '     CONFIGURACIÓN PREDETERMINADA DEL SISTEMA  '
                    echo '================================================'
                    configPredeterminada.each { k, v -> echo "  ${k.padRight(30)}: ${v}" }
                    
                    echo '\n================================================'
                    echo '          CONFIGURACIÓN DEL PROYECTO           '
                    echo '================================================'
                    configProyecto.each { k, v -> echo "  ${k.padRight(30)}: ${v}" }
                    
                    echo '\n================================================'
                    echo '        CONFIGURACIÓN DE MÁQUINA VIRTUAL       '
                    echo '================================================'
                    configVM.each { k, v -> echo "  ${k.padRight(30)}: ${v}" }
                    
                    echo '\n================================================'
                    echo '         CONFIGURACIÓN DE ALMACENAMIENTO       '
                    echo '================================================'
                    configAlmacenamiento.each { k, v -> echo "  ${k.padRight(30)}: ${v}" }
                    
                    echo '\n================================================'
                    echo '            CONFIGURACIÓN DE RED               '
                    echo '================================================'
                    configRed.each { k, v -> echo "  ${k.padRight(30)}: ${v}" }
                    
                    echo '\n================================================'
                    echo '         CONFIGURACIÓN DE SEGURIDAD            '
                    echo '================================================'
                    configSeguridad.each { k, v -> echo "  ${k.padRight(30)}: ${v}" }
                    
                    echo '\n================================================'
                    echo '          CONFIGURACIÓN DE GESTIÓN             '
                    echo '================================================'
                    configGestion.each { k, v -> echo "  ${k.padRight(30)}: ${v}" }
                    
                    echo '\n================================================'
                    echo '   CONFIGURACIÓN VALIDADA Y LISTA             '
                    echo '================================================\n'
                }
            }
        }

        stage('Resumen Pre-Despliegue') {
            steps {
                script {
                    echo '\n================================================'
                    echo '           RESUMEN PRE-DESPLIEGUE              '
                    echo '================================================'
                    echo "  Ubicación: ${params.REGION} / ${params.ZONE}"
                    echo "  VM: ${params.VM_NAME}"
                    echo "  OS: ${params.OS_TYPE}"
                    echo "  Tipo: ${params.VM_TYPE}-${params.VM_CORES}-${params.VM_MEMORY * 1024}"
                    echo "  Disco: ${params.DISK_SIZE} GB (${params.DISK_TYPE})"
                    echo "  Red: ${params.VPC_NETWORK}"
                    echo "  Firewall: ${params.FIREWALL_RULES}"
                    echo "  Ambiente: ${params.ENVIRONMENT}"
                    echo '================================================\n'
                    
                    if (params.INFRAESTRUCTURE_TYPE == 'Preemptible') {
                        echo 'ADVERTENCIA: VM Preemptible puede ser interrumpida'
                        echo '   Esta configuración es ideal para cargas de trabajo tolerantes a interrupciones\n'
                    }
                }
            }
        }
    }

    post {
        success {
            echo '\nPipeline ejecutado exitosamente'
        }
        failure {
            echo '\nPipeline falló durante la ejecución'
        }
        always {
            echo '\n================================================'
            echo '            FIN DE LA EJECUCIÓN                '
            echo "  Fecha: ${new Date()}"
            echo '================================================'
        }
    }
}