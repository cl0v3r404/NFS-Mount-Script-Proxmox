#!/bin/bash

# --- CONFIGURACIÓN ---
PROXMOX_IP=" "
STORAGE_IP=" "

# Lista de carpetas a montar: "Carpeta_Remota:Carpeta_Local". Puedes agregar tantas líneas como necesites
MOUNTS=(

)

# IDs de los LXC separados por espacio
LXCS=()

# --- FASE 1: ASEGURAR EXPORTACIONES --- 
echo "Esperando a que el servidor NFS publique las rutas..." 
exportfs -ar 
sleep 5

# --- EJECUCIÓN ---

echo "Iniciando montajes remotos en Proxmox..."

# Iniciamos el banderín de error en 0 (Todo en paz)
ERROR_DETECTADO=0

for item in "${MOUNTS[@]}"; do
    REMOTE_PATH="${item%%:*}"
    LOCAL_PATH="${item##*:}"

    echo "Procesando $LOCAL_PATH..."

    IS_MOUNTED=$(ssh root@$PROXMOX_IP "mountpoint -q $LOCAL_PATH && echo 'yes' || echo 'no'")

    if [ "$IS_MOUNTED" == "no" ]; then
        echo "Montando $REMOTE_PATH en $LOCAL_PATH..."
        
        # Ejecutamos el mount tradicional por SSH
        ssh root@$PROXMOX_IP "mount -t nfs -o rw,relatime,soft,timeo=30,retrans=2,rsize=1048576,wsize=1048576,nolock,_netdev $STORAGE_IP:$REMOTE_PATH $LOCAL_PATH"
        
        # Verificamos si el comando anterior tuvo éxito ($? es el código de salida)
        if [ $? -ne 0 ]; then
            echo "¡Fallo detectado al montar $LOCAL_PATH!"
            ERROR_DETECTADO=1
        fi
    else
        echo "El punto $LOCAL_PATH ya está montado."
    fi
done

# --- FASE 2: EL CORTAFUEGOS (FAIL-SAFE) ---
# Si hay algún error, no se montarán
if [ $ERROR_DETECTADO -eq 1 ]; then
    echo "====================================================="
    echo "¡ALERTA! Uno o más montajes NFS han fallado."
    echo "Para proteger la integridad de los datos, los LXC no se iniciarán."
    echo "Revisa la conexión entre tu almacenamiento y Proxmox."
    echo "====================================================="
    exit 1
fi

# Espera de seguridad
sleep 2

# --- FASE 3: Iniciar LXCs ---
for id in "${LXCS[@]}"; do
    STATUS=$(ssh root@$PROXMOX_IP "pct status $id")
    if [[ $STATUS == *"status: stopped"* ]]; then
        echo "Iniciando LXC $id..."
        ssh root@$PROXMOX_IP "pct start $id"
    else
        echo "LXC $id ya está activo."
    fi
done

echo "Proceso finalizado con éxito."