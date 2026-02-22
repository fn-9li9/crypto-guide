# Guía de Automatización Criptográfica y Sistemas de Identificación Digital con Enfoque SRE

**Asignatura:** Seguridad Informática  
**Unidad:** 4 — Sistemas de Identificación. Criptografía  
**Enfoque:** Site Reliability Engineering (SRE) — Automatización y Reproducibilidad  
**Entorno:** NixOS en WSL2 con Fish Shell

---

## Índice

1. [Resumen Teórico](#1-resumen-teórico)
2. [Objetivos](#2-objetivos)
3. [Justificación](#3-justificación)
4. [Entorno de Trabajo](#4-entorno-de-trabajo)
5. [Casos Prácticos](#5-casos-prácticos)
6. [Mejoras SRE Más Allá del Libro](#6-mejoras-sre-más-allá-del-libro)

---

## 1. Resumen Teórico

### 1.1 Métodos para Asegurar la Privacidad de la Información

Desde los primeros mensajes escritos, la necesidad de proteger la información confidencial ha impulsado el desarrollo de la criptografía. En el contexto actual de infraestructuras distribuidas, esta necesidad se traduce en garantizar que los datos en tránsito y en reposo permanezcan inaccesibles para actores no autorizados. Los métodos de ocultación de información se clasifican históricamente en sistemas de transposición (como la escítala espartana, que reorganiza el orden de los caracteres) y sistemas de sustitución (como el cifrador de Polybios o el cifrador del César, que reemplazan caracteres por otros equivalentes).

### 1.2 Criptografía Simétrica

La criptografía simétrica, también conocida como cifrado de clave privada o clave secreta, utiliza una única clave compartida tanto para cifrar como para descifrar la información. Su principal ventaja es la velocidad; su principal desventaja es el problema de distribución de claves: cómo comunicar la clave de forma segura entre emisor y receptor, especialmente cuando estos no se conocen o están geográficamente separados. Algoritmos representativos incluyen DES, 3DES, AES (estándar actual) e IDEA. En entornos SRE, el cifrado simétrico se emplea habitualmente para cifrar secretos en reposo (backups, bases de datos, archivos de configuración).

### 1.3 Criptografía Asimétrica

Propuesta en 1976 por Whitfield Diffie y Martin Hellman, la criptografía asimétrica o de clave pública resuelve el problema de distribución de claves. Cada participante posee un par de claves matemáticamente relacionadas: una clave pública, que puede compartirse libremente, y una clave privada, que nunca debe revelarse. El emisor cifra el mensaje con la clave pública del receptor; solo la clave privada correspondiente puede descifrarlo. Los algoritmos más utilizados son RSA, DSA y EIGamal. La seguridad matemática de RSA se basa en la dificultad computacional de factorizar el producto de dos números primos grandes.

### 1.4 Funciones de Resumen (Hash)

Las funciones hash son funciones de sentido único que asocian a cualquier documento un valor numérico de longitud fija, denominado resumen o huella digital. Sus propiedades fundamentales son la resistencia a la preimagen (imposibilidad práctica de reconstruir el documento a partir del hash) y la resistencia a colisiones (dificultad de encontrar dos documentos con el mismo hash). Los algoritmos más extendidos son MD5 (128 bits, actualmente considerado inseguro) y SHA-2 (SHA-256, SHA-512). En operaciones SRE, los hashes garantizan la integridad de artefactos, binarios y configuraciones en pipelines de entrega continua.

### 1.5 Firma Digital

La firma digital es el mecanismo criptográfico que sustituye a la firma manuscrita en el mundo digital. El proceso consiste en calcular el hash del documento y cifrarlo con la clave privada del firmante. El resultado es la firma digital, que se adjunta al documento. Cualquier receptor puede verificar la firma descifrándola con la clave pública del firmante y comparando el hash resultante con el hash calculado del documento recibido. Si coinciden, el documento es auténtico e íntegro. La firma digital garantiza autenticidad, integridad y no repudio, pero no implica necesariamente cifrado del contenido.

### 1.6 Certificado Digital

Un certificado digital X.509 es un documento electrónico que vincula una clave pública con la identidad de su propietario, respaldado por la firma digital de una autoridad certificadora (CA) de confianza. Contiene campos estandarizados: versión, número de serie, algoritmo de firma, emisor (CA), periodo de validez, propietario (sujeto), clave pública, firma de la CA y extensiones de uso. El formato X.509 es el estándar predominante en Internet. En España, la Fábrica Nacional de Moneda y Timbre actúa como CA raíz para los certificados de ciudadanos.

### 1.7 Infraestructura de Clave Pública (PKI)

La PKI (Public Key Infrastructure) es el conjunto de hardware, software, políticas y procedimientos necesarios para la gestión del ciclo de vida de certificados digitales. Está compuesta por la Autoridad de Certificación (CA), responsable de emitir y revocar certificados; la Autoridad de Registro (RA), que verifica la identidad de los solicitantes; los repositorios de certificados y listas de revocación (CRL); y los clientes que consumen los certificados. La PKI permite alcanzar los cuatro objetivos fundamentales de la seguridad informática: autenticidad, confidencialidad, integridad y no repudio.

---

## 2. Objetivos

### 2.1 Objetivo General

Comprender, implementar y automatizar los sistemas criptográficos y de identificación digital descritos en la Unidad 4 del libro de texto, aplicando principios de Site Reliability Engineering para garantizar la reproducibilidad, trazabilidad y operación segura en entornos de infraestructura moderna.

### 2.2 Objetivos Específicos

Describir e identificar los sistemas lógicos de identificación criptográfica, incluyendo firma electrónica, certificado digital y PKI, relacionándolos con los requisitos de seguridad de sistemas de información reales.

Implementar cifrado simétrico y asimétrico mediante GnuPG en GNU/Linux, siguiendo el principio de Kerckhoff: la seguridad debe residir en la clave, no en el algoritmo.

Automatizar la generación, distribución, firma y revocación de claves criptográficas mediante scripts reproducibles en modo batch, eliminando la intervención manual y sus errores asociados.

Instalar y operar una Autoridad Certificadora propia con OpenSSL, reproduciendo el ciclo completo de emisión, verificación y revocación de certificados X.509.

Aplicar la perspectiva SRE al ciclo de vida de las claves: rotación planificada, almacenamiento seguro, recuperación ante fallos y monitorización de caducidad.

Integrar los conceptos criptográficos en flujos de trabajo de entrega continua, firma de artefactos y notificaciones seguras propios de entornos SRE modernos.

---

## 3. Justificación

### 3.1 Por qué la Automatización Criptográfica es Esencial en la Infraestructura Moderna

Las infraestructuras actuales gestionan miles de secretos, certificados y claves criptográficas distribuidas entre múltiples servicios, microservicios, nodos y regiones. Un proceso manual es inherentemente no escalable: un equipo SRE que gestione cien servicios no puede renovar manualmente cien certificados cada año sin incurrir en errores, omisiones o caducidades accidentales que deriven en interrupciones de servicio. La automatización criptográfica permite tratar los secretos como infraestructura: definidos en código, versionados, auditables y desplegables de forma reproducible.

### 3.2 Por qué la Reproducibilidad es Crítica en las Prácticas SRE

La reproducibilidad es uno de los pilares del paradigma de infraestructura como código. Cuando un proceso criptográfico es reproducible, cualquier miembro del equipo puede ejecutarlo en cualquier entorno y obtener el mismo resultado verificable. Esto elimina el problema del "funciona en mi máquina" aplicado a la seguridad: un certificado generado manualmente en el portátil del administrador y uno generado por un script auditado en un pipeline de CI/CD deben ser funcionalmente equivalentes. La reproducibilidad también facilita la auditoría y el cumplimiento normativo.

### 3.3 Por qué los Procedimientos Exclusivamente Manuales son Insuficientes

Los procedimientos manuales son fuente de error humano, inconsistencia y latencia. En el contexto de la criptografía, un error al copiar una passphrase, un olvido al generar el certificado de revocación o una renovación tardía de un certificado pueden traducirse en brechas de seguridad o indisponibilidades de servicio con impacto económico y reputacional. Además, los procesos manuales no escalan: a medida que la infraestructura crece, la deuda operativa de la gestión manual se convierte en un riesgo sistémico.

### 3.4 La Importancia de la Gestión del Ciclo de Vida de las Claves

Una clave criptográfica que no rota es una vulnerabilidad latente: si es comprometida en un momento X, todo el material cifrado antes de la rotación queda expuesto. La gestión del ciclo de vida incluye generación segura (entropía suficiente, algoritmo adecuado), distribución protegida, almacenamiento cifrado, rotación planificada, revocación de emergencia y eliminación segura. En SRE, este ciclo se codifica como política ejecutable, integrada con sistemas como HashiCorp Vault, AWS Secrets Manager o Google Cloud KMS, que automatizan la rotación y auditabilidad sin intervención humana.

---

## 4. Entorno de Trabajo

### 4.1 Instalación de NixOS en WSL (Windows Subsystem for Linux)

#### Descarga del archivo NixOS-WSL

```
https://github.com/nix-community/NixOS-WSL/releases/download/2505.7.0/nixos.wsl
```

#### Instalación

```powershell
wsl --install --from-file nixos.wsl
wsl -d NixOS
```

#### Post-instalación

```bash
sudo passwd nixos
sudo nix-channel --update
wsl -s NixOS
```

### 4.2 Instalación de Herramientas Requeridas

Dentro del entorno NixOS, instalar todas las herramientas necesarias:

```bash
nix-shell -p vim fish gnupg pinentry openssl
```

Para una sesión persistente, añadir al perfil de NixOS (`/etc/nixos/configuration.nix`):

```nix
environment.systemPackages = with pkgs; [
  vim
  fish
  gnupg
  pinentry
  openssl
  git
];
```

### 4.3 Configuración de GPG para WSL

Modificar el archivo de configuración del agente GPG:

```bash
mkdir -p ~/.gnupg
chmod 700 ~/.gnupg
```

Editar o crear `~/.gnupg/gpg-agent.conf`:

```
allow-loopback-pinentry
```

Aplicar los cambios reiniciando el agente:

```bash
gpgconf --kill gpg-agent
```

Esta configuración es obligatoria para que los scripts en modo batch (`--pinentry-mode loopback`) funcionen correctamente sin interfaz gráfica, lo que es esencial en entornos WSL, contenedores Docker y pipelines de CI/CD.

### 4.4 Uso de Fish Shell

Todos los scripts `.fish` de esta guía asumen ejecución en:

- **Shell:** Fish (Friendly Interactive Shell)
- **Entorno:** WSL2 con NixOS
- **Directorio de trabajo:** el mismo directorio donde se encuentran los scripts

Para iniciar Fish como shell predeterminado:

```bash
chsh -s $(which fish)
```

O ejecutar directamente:

```bash
fish
```

### 4.5 Archivo keyparams.conf

El archivo `keyparams.conf` es utilizado por `pc3-key-generation.fish` para la creación automatizada de pares de claves asimétricas en modo batch. Contenido del archivo:

```
%echo Generating RSA 4096-bit key pair (SRE Cryptography Guide)

Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096

Name-Real: Fernando Delgado
Name-Comment: Tecnico de Seguridad Informatica - SiTour
Name-Email: f.delgado@sitour.com

Expire-Date: 1y

Passphrase: SRE-Demo-Passphrase-2024!

%commit
%echo Key generation complete.
```

**Parámetros clave:**

| Parámetro     | Valor        | Justificación                                            |
| ------------- | ------------ | -------------------------------------------------------- |
| `Key-Type`    | RSA          | Estándar ampliamente soportado, compatible con GPG       |
| `Key-Length`  | 4096         | Máxima seguridad disponible en GPG; recomendado NIST     |
| `Expire-Date` | 1y           | Política de rotación anual; nunca usar `0` en producción |
| `Passphrase`  | valor fuerte | En producción, inyectar desde secret manager             |

**Importante para producción:** la passphrase nunca debe estar en texto plano en el archivo. En entornos CI/CD, inyectarla como variable de entorno:

```bash
sed -i "s/Passphrase: .*/Passphrase: ${GPG_PASSPHRASE}/" keyparams.conf
fish pc3-key-generation.fish keyparams.conf
# Restaurar placeholder inmediatamente después
```

---

## 5. Casos Prácticos

### PC1 — Cifrador de Polybios

**Archivo:** `pc1-polybius-cipher.fish`

Implementa el cifrador de sustitución de Polybios (siglo II a.C.) usando una cuadrícula 5×5. Cada letra se sustituye por el par fila-columna de su posición en la tabla. Las letras I y J comparten posición. Demuestra los fundamentos de los sistemas de sustitución numérica.

```bash
# Modo demo (ejemplo del libro de texto)
fish pc1-polybius-cipher.fish

# Cifrar un mensaje
fish pc1-polybius-cipher.fish encrypt "el cifrador de Polybios"

# Descifrar
fish pc1-polybius-cipher.fish decrypt "15 31 13 24 ..."
```

---

### PC2 — Cifrado Simétrico con GnuPG

**Archivo:** `pc2-symmetric-encryption.fish`

Cifra y descifra un documento usando AES-256 en modo simétrico con GnuPG. Produce salida binaria (`.gpg`) y ASCII-armored (`.asc`). Verifica la integridad comparando el archivo original con el recuperado.

```bash
fish pc2-symmetric-encryption.fish [passphrase] [archivo]
```

Opciones GPG utilizadas:

- `--symmetric`: cifrado simétrico (clave compartida)
- `--cipher-algo AES256`: algoritmo de cifrado
- `--armor`: salida en formato ASCII (portátil)
- `--batch --yes --pinentry-mode loopback`: modo no interactivo

---

### PC3 — Generación de Par de Claves Asimétricas

**Archivo:** `pc3-key-generation.fish`

Genera un par de claves RSA 4096 bits usando `keyparams.conf` en modo batch. Configura automáticamente el agente GPG para loopback pinentry, exporta la clave pública y la lista en el anillo de claves.

```bash
fish pc3-key-generation.fish [ruta/a/keyparams.conf]
```

---

### PC4 — Generación de Certificado de Revocación

**Archivo:** `pc4-revocation-certificate.fish`

Genera inmediatamente después de la creación de la clave un certificado de revocación preventivo, siguiendo la recomendación explícita del libro de texto. El certificado se almacena con permisos 400 en directorio protegido.

```bash
fish pc4-revocation-certificate.fish [identificador_clave] [passphrase]
```

**Razones de revocación disponibles:**

| Código | Motivo                 |
| ------ | ---------------------- |
| 0      | Sin razón especificada |
| 1      | Clave comprometida     |
| 2      | CA comprometida        |
| 3      | Afiliación modificada  |
| 4      | Reemplazada            |

---

### PC5 — Intercambio de Claves con GPG

**Archivo:** `pc5-key-exchange.fish`

Automatiza la exportación e importación de claves públicas entre usuarios, simulando el intercambio Fernando-Macarena del libro de texto. Muestra huellas digitales para verificación out-of-band.

```bash
fish pc5-key-exchange.fish export [id_clave] [archivo_salida]
fish pc5-key-exchange.fish import [archivo_clave]
fish pc5-key-exchange.fish demo
```

---

### PC6 — Firma Digital de un Documento

**Archivo:** `pc6-digital-signature.fish`

Firma un documento usando los tres métodos disponibles en GPG (`--clearsign`, `-s`, `-b`) y verifica todas las firmas. Demuestra que la firma garantiza autenticidad e integridad sin necesariamente cifrar el contenido.

```bash
fish pc6-digital-signature.fish [documento] [passphrase]
```

**Métodos de firma:**

| Opción        | Resultado                                  | Uso típico                  |
| ------------- | ------------------------------------------ | --------------------------- |
| `--clearsign` | Texto legible + firma al final (`.asc`)    | Emails, documentos de texto |
| `-s --armor`  | Documento + firma comprimidos (`.asc`)     | Distribución general        |
| `-b --armor`  | Solo la firma en archivo separado (`.sig`) | Binarios, ejecutables, ISOs |

---

### PC7 — Instalación de Autoridad Certificadora

**Archivo:** `pc7-certificate-authority.sh`

Crea una CA raíz independiente con OpenSSL, equivalente a la entidad emisora de certificados del libro de texto. Genera la estructura de directorios, el archivo de configuración OpenSSL, la clave privada RSA 4096 y el certificado auto-firmado X.509.

```bash
bash pc7-certificate-authority.sh [nombre_CA] [directorio_CA]
```

Estructura generada:

```
/tmp/ca-SiTourCA/
├── certs/          (certificados emitidos)
├── crl/            (listas de revocación)
├── newcerts/       (copias de certificados)
├── private/        (clave privada CA - modo 700)
├── requests/       (peticiones pendientes)
├── index.txt       (base de datos de certificados)
├── serial          (contador de números de serie)
└── openssl.cnf     (configuración OpenSSL)
```

---

### PC8 — Petición y Revocación de Certificados

**Archivo:** `pc8-certificate-request.sh`

Implementa el ciclo completo de vida de un certificado: generación de clave de usuario, creación de CSR, firma por la CA, emisión, verificación, revocación y actualización de CRL. Corresponde al proceso del libro de texto pero usando OpenSSL en lugar del IIS de Windows.

```bash
bash pc8-certificate-request.sh [directorio_CA] [nombre_usuario] [email]
```

---

### PC9 — Cifrado de Correo con Certificado Digital

**Archivo:** `pc9-secure-email.md`

Explicación conceptual completa del proceso de firma y cifrado de correo electrónico con certificados X.509 (S/MIME) y OpenPGP. Incluye configuración en Thunderbird, automatización CLI con msmtp y comparativa S/MIME vs OpenPGP.

---

## 6. Mejoras SRE Más Allá del Libro

Esta sección propone mejoras operativas que van más allá del contenido del libro de texto, aplicando principios y herramientas propios del Site Reliability Engineering moderno.

### 6.1 Políticas de Rotación de Claves

El libro de texto menciona que las claves deben modificarse periódicamente por seguridad, pero no define una política. En SRE, la rotación de claves debe ser automatizada y codificada como política:

- Las claves GPG deben tener una fecha de caducidad no superior a dos años y rotarse antes de su expiración.
- Los certificados X.509 deben renovarse cuando queden menos de 30 días para su caducidad.
- Herramientas como cert-manager (Kubernetes), Vault Agent o aws-acm automatizan la renovación sin intervención humana.
- Las alertas de caducidad próxima deben integrarse en los sistemas de monitorización (Prometheus, Datadog, PagerDuty).

### 6.2 Estrategia de Backup de Claves

El libro advierte que las claves privadas nunca deben estar en papel accesible, pero no define una estrategia de backup. En SRE se recomienda:

- Almacenar el backup de claves privadas en un sistema de gestión de secretos (HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager).
- Mantener una copia offline cifrada en un dispositivo USB guardado físicamente en una ubicación segura distinta al datacenter principal.
- Los certificados de revocación deben almacenarse separados de la clave privada, en una ubicación de solo lectura con acceso auditado.
- Documentar y probar el procedimiento de recuperación ante un escenario de pérdida total de claves.

### 6.3 Almacenamiento Offline del Certificado de Revocación

El libro recomienda generar el certificado de revocación inmediatamente después de crear la clave, lo cual es correcto. La mejora SRE añade:

- El certificado de revocación debe almacenarse en al menos tres ubicaciones separadas (regla 3-2-1 adaptada a secretos).
- El acceso al certificado de revocación debe requerir autenticación multifactor y dejar rastro de auditoría.
- Se debe probar periódicamente que el certificado de revocación es válido y puede publicarse en los keyservers correspondientes.

### 6.4 Firma de Artefactos en Pipelines CI/CD

El libro trata la firma de documentos en el contexto personal. En SRE moderno, la firma criptográfica de artefactos es una práctica fundamental de la cadena de suministro de software (supply chain security):

- Cada binario, imagen Docker, chart de Helm o paquete debe estar firmado antes de ser desplegado a producción.
- Herramientas como Sigstore/Cosign, GPG o Notary permiten firmar y verificar artefactos en pipelines automatizados.
- La verificación de firma debe ser un paso obligatorio en el proceso de despliegue, bloqueando artefactos no firmados o con firmas inválidas.
- Esto implementa el principio de no repudio a nivel de operaciones: cada despliegue queda vinculado criptográficamente a quien lo autorizó.

### 6.5 Verificación Segura de Distribución de Claves

El intercambio de claves descrito en el libro (Fernando exporta y Macarena importa) es correcto pero incompleto desde una perspectiva de seguridad operativa. La mejora SRE incluye:

- Verificar siempre la huella digital (fingerprint) de la clave recibida mediante un canal de comunicación alternativo y fuera de banda (llamada telefónica, reunión presencial, plataforma de chat corporativa).
- En entornos empresariales, usar un keyserver interno (como Keybase for Teams o un servidor LDAP con certificados) para la distribución controlada de claves públicas.
- Implementar Web of Trust o una PKI jerárquica en lugar de confiar en claves no verificadas.
- Registrar en el sistema de gestión de cambios qué claves fueron importadas, cuándo y por quién.

### 6.6 Automatización como Principio Rector

El libro de texto presenta procedimientos interactivos paso a paso, lo cual es adecuado para el aprendizaje. Sin embargo, en un entorno de producción real, cualquier procedimiento que requiera más de un comando manual es un candidato a la automatización. La justificación técnica es la siguiente:

- Los procedimientos interactivos no son auditables: no queda registro de los parámetros exactos utilizados.
- Los procedimientos interactivos no son reproducibles: el resultado depende de la interpretación de quien los ejecuta.
- Los procedimientos interactivos no escalan: un equipo de dos personas puede seguirlos; un equipo de veinte no puede hacerlo de forma consistente.

Por estas razones, todos los casos prácticos de esta guía implementan las directivas `--batch`, `--yes` y `--pinentry-mode loopback` en cada llamada a GPG, y cada parámetro está documentado y justificado en el código fuente del script correspondiente.

---

## Estructura de Archivos

```
crypto-guide/
├── README.md                         (este documento)
├── keyparams.conf                    (parámetros de generación de claves)
├── pc1-polybius-cipher.fish          (cifrador de Polybios)
├── pc2-symmetric-encryption.fish     (cifrado simétrico AES-256 con GPG)
├── pc3-key-generation.fish           (generación de par de claves RSA 4096)
├── pc4-revocation-certificate.fish   (certificado de revocación GPG)
├── pc5-key-exchange.fish             (intercambio de claves públicas)
├── pc6-digital-signature.fish        (firma digital de documentos)
├── pc7-certificate-authority.sh      (instalación de CA con OpenSSL)
├── pc8-certificate-request.sh        (petición y revocación de certificados)
└── pc9-secure-email.md               (correo cifrado con certificado digital)
```

---

## Referencia Bibliográfica

CESAR SEOANI — _Seguridad Informática_, Unidad 4: Sistemas de Identificación. Criptografía, páginas 80-106.

---

_Guía generada con enfoque SRE — Todos los scripts son reproducibles, no interactivos y adecuados para entornos de producción con las adaptaciones de seguridad descritas en la sección de Mejoras SRE._
