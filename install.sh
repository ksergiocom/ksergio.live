#!/bin/bash

# 1. Cambiar al directorio del script
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
cd "$SCRIPT_DIR" || exit 1

# 2. Permisos de root
if [ "$EUID" -ne 0 ]; then
    echo "El script necesita permisos de administrador (sudo)"
    exit 1
fi

# 3. Comprobando dependencias
missing=0
for d in 'node' 'npm' 'nginx' 'systemctl'
do
    if ! command -v "$d" &> /dev/null; then
        missing=1
        echo "$d ¡NO INSTALADO!"
    fi
done

if [ "$missing" -eq 1 ]; then
    echo "---------"
    echo "Por favor instala las dependencias faltantes"
    exit 1
fi

# 4. Pedir datos
read -p "¿Cuál es tu dominio? (Enter para '_'): " dominio
read -p "¿Qué puerto usar? (Enter para 7777): " puerto

# --- CORRECCIÓN AQUÍ ---
# Agregados espacios dentro de [ ] y corregido el check de dominio
if [ -z "$puerto" ]; then
    puerto=7777
fi

if [ -z "$dominio" ]; then
    dominio="_"
fi

# 5. Iniciar proyecto de Node
# Solo si no existe ya el package.json
if [ ! -f "package.json" ]; then
    npm init -y
    npm i express
fi

# 6. Alterar ficheros con sed
# Usamos | como delimitador en todos para evitar líos con rutas
sed -i "s|const PORT = [0-9]*|const PORT = $puerto|" index.js
sed -i "s|server_name .*|server_name $dominio;|" nginx.conf
sed -i "s|proxy_pass http://127.0.0.1:[0-9]*/|proxy_pass http://127.0.0.1:$puerto/|" nginx.conf

# 7. Configuración de Systemd
NODE_PATH=$(command -v node)
REAL_USER=${SUDO_USER:-$USER}

if [ -f "curl_yo.service" ]; then
    sed -i "s|ExecStart=.*|ExecStart=$NODE_PATH $SCRIPT_DIR/index.js|" curl_yo.service
    sed -i "s|WorkingDirectory=.*|WorkingDirectory=$SCRIPT_DIR|" curl_yo.service
    sed -i "s|User=.*|User=$REAL_USER|" curl_yo.service

    cp curl_yo.service /etc/systemd/system/curl_yo.service
    systemctl daemon-reload
    systemctl enable curl_yo
    systemctl restart curl_yo
else
    echo "Aviso: No se encontró curl_yo.service, saltando paso de systemd."
fi

# 8. Configuración de Nginx
CONF_NAME="curl_yo"
if [ -f "nginx.conf" ]; then
    cp nginx.conf /etc/nginx/sites-available/$CONF_NAME
    # Crear enlace si no existe
    ln -sf /etc/nginx/sites-available/$CONF_NAME /etc/nginx/sites-enabled/
    
    if nginx -t &> /dev/null; then
        systemctl restart nginx
        echo "------------------------------------------------"
        echo "¡TODO LISTO!"
        echo "Servicio Node.js corriendo como usuario: $REAL_USER"
        echo "Dominio configurado: $dominio"
        echo "Puerto: $puerto"
        echo "Acceso: `curl http://$dominio`"
        echo "------------------------------------------------"
    else
        echo "Error: Nginx test falló. Revisa /etc/nginx/sites-available/$CONF_NAME"
    fi
else
    echo "Error: No se encontró nginx.conf"
fi