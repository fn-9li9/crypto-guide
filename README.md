# Laboratorio de Automatizacion Criptografica - Perspectiva SRE

Repositorio de automatizacion criptografica reproducible, orientado a la fiabilidad de
infraestructuras y al ciclo de vida de claves e identidades digitales.

---

## Requisitos

- Docker (version 20.10 o superior recomendada)
- Docker Compose (CLI moderno: `docker compose`, incluido en Docker Desktop y Docker Engine 20.10+)
- Sin dependencias adicionales en el sistema anfitrion: el contenedor provee el entorno completo

---

## Construccion del entorno

```
docker compose build
```

Este comando construye la imagen a partir del `Dockerfile` incluido. La imagen instala
GnuPG, OpenSSL, Fish shell, pinentry-curses y demas herramientas sobre `nixos/nix`
mediante `nix-env`. El proceso es determinista y reproducible.

La primera construccion descarga los paquetes de Nixpkgs y puede tardar varios minutos.
Las reconstrucciones posteriores aprovechan la cache de capas de Docker.

---

## Ejecucion del laboratorio

```
docker compose run crypto-lab
```

Inicia una sesion interactiva en Fish shell como root. Todos los scripts estan disponibles
en `/workspace/scripts/`.

Ejecucion de casos practicos en orden:

```
fish /workspace/scripts/pc1-polybius-cipher.fish
fish /workspace/scripts/pc2-symmetric-encryption.fish
fish /workspace/scripts/pc3-key-generation.fish
fish /workspace/scripts/pc4-revocation-certificate.fish
fish /workspace/scripts/pc5-key-exchange.fish
fish /workspace/scripts/pc6-digital-signature.fish
bash /workspace/scripts/pc7-certificate-authority.sh
bash /workspace/scripts/pc8-certificate-request.sh
```

El caso practico 9 es una guia conceptual en Markdown:

```
cat /workspace/scripts/pc9-secure-email.md
```

---

## Destruccion del entorno

```
docker compose down -v
```

La opcion `-v` elimina el volumen `gnupg-data`, borrando todas las claves GPG
generadas durante el laboratorio. Garantiza un reinicio limpio sin material criptografico
residual del ciclo anterior.

---

## Explicacion del aislamiento y reproducibilidad

### Imagen base NixOS

La imagen `nixos/nix` utiliza el gestor de paquetes Nix, que garantiza que cada
paquete instalado (GnuPG, OpenSSL, Fish) tiene una version exacta y reproducible
determinada por el canal de Nixpkgs activo en el momento del build. A diferencia de
`apt-get`, Nix no modifica el sistema base: todos los paquetes se instalan en el store
de Nix (`/nix/store`) con hashes criptograficos que identifican exactamente cada
version y sus dependencias transitivas.

El contenedor ejecuta como root porque la imagen `nixos/nix` no dispone de las
utilidades de gestion de usuarios (`useradd`, `adduser`) propias de distribuciones
como Debian o Alpine. Para un despliegue en produccion se recomienda construir sobre
una imagen derivada que incluya estas herramientas, o bien gestionar el acceso
mediante politicas de Docker y capabilities.

### Como los volumenes preservan el material criptografico

El volumen `gnupg-data` monta `/root/.gnupg` dentro del contenedor. Las claves
generadas en una sesion persisten en la siguiente sin necesidad de regenerarlas.
Al ejecutar `docker compose down -v` el volumen se elimina, lo que equivale a
destruir el anillo de claves por completo.

### Implicaciones de seguridad

- El directorio de claves `/root/.gnupg` tiene permisos 700, evitando lectura por
  otros procesos dentro del contenedor.
- Las frases de paso estan definidas en los scripts con fines educativos. En produccion
  deben provenir de un gestor de secretos (HashiCorp Vault, AWS Secrets Manager).
- `NIX_SSL_CERT_FILE` apunta al bundle de certificados raiz para que OpenSSL
  y GnuPG puedan verificar conexiones TLS desde dentro del contenedor NixOS.
- Los scripts de Bash usan `set -euo pipefail` para detener la ejecucion ante el
  primer error, evitando estados parciales silenciosos.

### Limitaciones

- El contenedor ejecuta como root al no haber gestion de usuarios en la imagen base.
- Las frases de paso en texto plano en los scripts son aceptables en laboratorio pero
  inaceptables en produccion.
- Los certificados de la CA (PC7/PC8) son autofirmados y no reconocidos por
  navegadores sin importacion manual del certificado raiz.
- La primera construccion de la imagen puede tardar 5-10 minutos por la descarga
  de paquetes desde el canal de Nixpkgs.
