# Laboratorio de Automatizacion Criptografica - Perspectiva SRE

Repositorio de automatizacion criptografica reproducible, orientado a la fiabilidad de
infraestructuras y al ciclo de vida de claves e identidades digitales.

---

## Requisitos

- Docker (version 20.10 o superior recomendada)
- Docker Compose (CLI moderno: `docker compose`, incluido en Docker Desktop y Docker Engine 20.10+)
- Sin dependencias adicionales en el sistema anfitron: el contenedor provee el entorno completo

---

## Construccion del entorno

```
docker compose build
```

Este comando construye la imagen a partir del `Dockerfile` incluido. La imagen instala
GnuPG, OpenSSL, Fish shell, pinentry-curses y demas herramientas necesarias sobre
`debian:stable-slim`. El proceso es determinista y reproducible.

---

## Ejecucion del laboratorio

```
docker compose run crypto-lab
```

Esto inicia una sesion interactiva en el contenedor con usuario no privilegiado (`cryptouser`).
Dentro del contenedor, todos los scripts estan disponibles en `/workspace/scripts/`.

Ejemplo de ejecucion de un caso practico:

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

El caso practico 9 es una guia conceptual en formato Markdown:

```
cat /workspace/scripts/pc9-secure-email.md
```

---

## Destruccion del entorno

```
docker compose down -v
```

La opcion `-v` elimina los volumenes asociados, incluyendo el directorio `.gnupg`
persistido. Esto garantiza un reinicio limpio del laboratorio sin material criptografico
residual del ciclo anterior.

---

## Explicacion del aislamiento y reproducibilidad

### Por que la contenedorizacion garantiza reproducibilidad

El contenedor define exactamente las versiones de todas las herramientas instaladas
mediante `apt-get` sobre `debian:stable-slim`. No existe dependencia del sistema
operativo del equipo anfitron ni de configuraciones locales del usuario. Cualquier
persona que ejecute `docker compose build` obtendrA exactamente el mismo entorno,
independientemente de si usa macOS, Windows o Linux, o de las herramientas que tenga
instaladas localmente.

Los scripts estan disenados con `--batch`, `--yes` y `--pinentry-mode loopback` para
ejecutarse sin intervencion humana. Esto permite su uso en pipelines CI/CD con el
mismo resultado que en una ejecucion manual.

### Como los volumenes preservan el material criptografico

El volumen `gnupg-data` monta el directorio `~/.gnupg` del usuario del contenedor.
Esto permite que las claves generadas en una sesion persistan en la siguiente sin
necesidad de regenerarlas. En un contexto de laboratorio, evita tener que re-generar
pares de claves en cada ejecucion. En produccion, este volumen deberia estar cifrado
y con acceso restringido.

### Implicaciones de seguridad

- El contenedor ejecuta como usuario no privilegiado (UID 1001), evitando operaciones
  como root que podrian comprometer el sistema anfitron.
- El directorio de claves privadas (`.gnupg/private-keys-v1.d/`) tiene permisos 700.
- Las frases de paso estan definidas en los scripts para fines educativos; en produccion
  deben provenir de un gestor de secretos (HashiCorp Vault, AWS Secrets Manager, etc.).
- Los scripts incluyen `set -euo pipefail` (Bash) para detener la ejecucion ante errores.

### Limitaciones

- Las frases de paso en texto plano dentro de los scripts son aceptables en un entorno
  de laboratorio educativo, pero constituyen un riesgo inaceptable en produccion.
- La imagen no esta pensada para uso en produccion sin una revision de seguridad previa.
- El volumen `gnupg-data` no esta cifrado a nivel de Docker; el cifrado debe aplicarse
  a nivel del sistema de archivos del anfitron si se requiere.
- Los certificados de la CA generados en PC7/PC8 son autofirmados y no reconocidos
  por navegadores ni clientes de correo sin importacion manual.
