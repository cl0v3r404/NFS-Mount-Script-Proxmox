# NFS-Mount-Script-Proxmox
Script para montar recursos NFS desde un NAS o servidor Linux hacia Proxmox

## Descripción
Este script realiza montaje de recursos NFS en el host Proxmox, esto es ideal cuando se ejecuta un servidor de archivos virtualizado en Proxmox y se tienen que compartir carpetas con algún LXC o con el host propiamente. Este método es especifico para contenedores LXC *unprivileged*. 

## Paso 1: Establecer confianza con el host
Primero tenemos que permitir una conexión SSH sin contraseña para que se realicen las operaciones del script sin que nos solicite la contraseña. 
1. En la consola de Linux (el servidor de archivos) generamos una clave para el usuario root (o el usuario que se utilice)
   ```
    ssh-keygen -t rsa -b 4096
    ```
2. Enviamos la clave al destino, en este caso Proxmox
    ```
    ssh-copy-id root@[ip-de-proxmox]
    ```
    Si pide la clave de Proxmox, introducela, a partir de esto ya no será necesario.

## Paso 2: Script
1. Creamos el script, recomendado en la ubicación `/usr/local/bin`
 Puedes descargarlo o copiar y pegar el contenido en un archivo
```
wget https://raw.githubusercontent.com/cl0v3r404/NFS-Mount-Script-Proxmox/refs/heads/main/mount-nfs.sh
```

o

```
curl -O https://raw.githubusercontent.com/cl0v3r404/NFS-Mount-Script-Proxmox/refs/heads/main/mount-nfs.sh
```

3. Asignale permisos de ejecución al script
```
chmod +x /usr/local/bin/mount-nfs.sh
```

## Paso 3: Disparador automatico
Para hacer que sea posible la ejecución del script cuando el servicio NFS esté listo y la red lista, creamos un servicio de SystemD en la ruta `/etc/systemd/system/`

1. Pega la siguiente configuración
```
[Unit]
Description=Notifica a Proxmox para montar NFS e iniciar LXCs
After=nfs-server.service
Requires=nfs-server.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/mountnfs.sh # Cambia según tu ruta y nombre del archivo
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

3. Activamos el servicio
```
systemctl daemon-reload
systemctl enable mount-proxmox.service
``` 

