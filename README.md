# Laboratorio de Automatizacion Criptografica - Perspectiva SRE

Repositorio de automatizacion criptografica reproducible, orientado a la fiabilidad de infraestructuras, gestion del ciclo de vida de claves e identidades digitales, y ejecucion determinista de procesos criptograficos.

El entorno esta completamente contenido en Docker utilizando una imagen basada en **Nix**, garantizando reproducibilidad independiente del sistema anfitrion.

---

## Requisitos

- Docker 20.10 o superior
- Docker Compose CLI moderno (`docker compose`)
- No se requieren dependencias adicionales en el sistema anfitrion

El entorno completo (GnuPG, OpenSSL, Fish, Vim, pinentry, etc.) se instala dentro del contenedor mediante Nix.

---

## Arquitectura del Entorno

- Imagen base: `nixos/nix`
- Gestor de paquetes: Nix
- Shell principal: Fish
- Material criptografico persistido mediante volumen Docker
- Ejecucion no interactiva de GPG usando:
  - `--batch`
  - `--yes`
  - `--pinentry-mode loopback`

El directorio de claves se ubica en:

```
/root/.gnupg
```

y se persiste mediante el volumen:

```
gnupg-data
```

---

## Construccion del Entorno

```
docker compose build
```

Este comando:

1. Descarga la imagen `nixos/nix`
2. Actualiza los canales Nix
3. Instala:
   - gnupg
   - fish
   - openssl
   - vim
   - pinentry-curses
   - cacert

4. Configura `gpg-agent` para permitir `loopback pinentry`

El resultado es un entorno determinista y reproducible.

---

## Ejecucion del Laboratorio

```
docker compose run crypto-lab
```

Esto inicia una sesion interactiva en el contenedor.

Dentro del contenedor:

```
fish
```

Los scripts estan disponibles en:

```
/workspace/scripts/
```

---

## Ejecucion de Casos Practicos

### Cifrados clasicos

```
fish /workspace/scripts/pc1-polybius-cipher.fish
```

### Criptografia moderna con GPG

```
fish /workspace/scripts/pc2-symmetric-encryption.fish
fish /workspace/scripts/pc3-key-generation.fish
fish /workspace/scripts/pc4-revocation-certificate.fish
fish /workspace/scripts/pc5-key-exchange.fish
fish /workspace/scripts/pc6-digital-signature.fish
```

### Infraestructura de certificados (OpenSSL)

```
bash /workspace/scripts/pc7-certificate-authority.sh
bash /workspace/scripts/pc8-certificate-request.sh
```

### Caso 9 (Guia conceptual)

```
cat /workspace/scripts/pc9-secure-email.md
```

---

## Destruccion del Entorno

Para detener contenedores:

```
docker compose down
```

Para eliminar tambien el material criptografico persistido:

```
docker compose down -v
```

La opcion `-v` elimina el volumen `gnupg-data`, borrando completamente el keyring.

---

## Explicacion de Reproducibilidad con Nix

### Por que Nix garantiza determinismo

Nix instala paquetes mediante derivaciones inmutables almacenadas en:

```
/nix/store
```

Cada paquete esta identificado por un hash criptografico que depende de:

- Version exacta
- Dependencias
- Parametros de compilacion

Esto elimina:

- "Works on my machine"
- Drift entre entornos
- Dependencias implicitas del sistema anfitrion

El entorno es identico en:

- Windows (Docker Desktop)
- macOS
- Linux

---

## Automatizacion No Interactiva (SRE Approach)

Los scripts usan:

- `--batch`
- `--yes`
- `--pinentry-mode loopback`
- Configuracion `allow-loopback-pinentry` en `gpg-agent.conf`

Esto permite:

- Ejecucion en CI/CD
- Integracion en pipelines
- Automatizacion completa sin intervencion humana

---

## Persistencia del Material Criptografico

El volumen:

```
gnupg-data
```

monta:

```
/root/.gnupg
```

Esto permite:

- Mantener claves entre reinicios
- Simular ciclo de vida real
- Evitar regeneracion innecesaria

En entornos productivos, este volumen deberia:

- Estar cifrado a nivel de filesystem
- Tener control de acceso estricto
- Integrarse con un HSM o gestor de secretos

---

## Implicaciones de Seguridad

- El aislamiento lo provee Docker como boundary de ejecucion.
- El contenedor no modifica el sistema anfitrion.
- Las claves privadas permanecen dentro del volumen.
- Las passphrases en scripts son educativas.
- En produccion deben provenir de:
  - Vault
  - AWS Secrets Manager
  - Azure Key Vault
  - GCP Secret Manager

---

## Limitaciones del Laboratorio

- No es un entorno productivo.
- Las passphrases en texto plano son solo para fines academicos.
- El volumen Docker no esta cifrado por defecto.
- Los certificados generados en PC7/PC8 son autofirmados.
- No se implementa HSM ni proteccion hardware.
