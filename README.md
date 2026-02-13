# curl yo.ksergio.com

Esto es un clon inspirado de parrot.live

```bash
# ¡Cuidado epilépticos!
curl yo.ksergio.com
```

![gif](./res.gif)

## Como usar
### Script
Ejecuta el script como root o sudo para que configure todo automáticamente.
Tiene dependencias, te avisará si te falta algo. Instalaló con `apt install <dependencia>`
Si quieres puedes hacerlo a mano.

### ¡A mano!
- Necesario tener node instalado
- Hacer **npm init -y** y **npm i express**
- Ajustar **curl_yo.service** y enchufarlo a **/etc/systemd/system/...** y hacer systemctl daemon-reload y levantar el servicio
- Ajustar la configuracion de nginx para hacer de reverse proxy al servidor y reiniciar nginx
