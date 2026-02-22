# Automatizacion Criptografica y Sistemas de Identificacion Digital

## Perspectiva de Ingenieria de Fiabilidad de Sitios (SRE)

---

## 1. Resumen Teorico

### Privacidad de la Informacion

La necesidad de garantizar la confidencialidad en la transmision de informacion es tan
antigua como la escritura misma. Desde la escitala espartana del siglo V a.C. hasta los
algoritmos modernos AES y RSA, el objetivo ha sido siempre el mismo: que unicamente
el destinatario legitimo pueda interpretar un mensaje. En el contexto actual de la
ingenieria de infraestructuras, esta necesidad se traduce en requisitos operativos
concretos: cifrado en transito (TLS), cifrado en reposo (disco cifrado, secretos en
bóveda), autenticacion mutua y trazabilidad de accesos.

Desde la perspectiva SRE, la privacidad de la informacion no es una consideracion
opcional sino un requisito de fiabilidad: una filtracion de datos constituye un incidente
de disponibilidad e integridad que puede derivar en consecuencias legales, financieras y
reputacionales para la organizacion.

### Criptografia Simetrica

La criptografia simetrica utiliza la misma clave tanto para cifrar como para descifrar.
Sus principales exponentes clasicos son el cifrado del Cesar (sustitución con
desplazamiento fijo) y el cifrado de Vigenere (polialfabetico con palabra clave).
Los algoritmos modernos de clave privada incluyen DES, 3DES, AES y RC4.

El principio de Kerckhoff establece que la seguridad de un sistema debe residir en la
clave, no en el algoritmo. Esta premisa es fundamental en SRE: los algoritmos son
publicos y ampliamente estudiados; lo que debe protegerse con rigor es el material de
clave.

La principal limitacion de la criptografia simetrica es la distribucion de claves: para
que n entidades puedan comunicarse de forma segura entre si, se necesitan n\*(n-1)/2
claves compartidas. Para 100 usuarios esto representa 4950 secretos compartidos, lo
que hace el sistema inmanejable a escala.

Aplicacion SRE: el cifrado simetrico con AES-256 es el estandar para cifrar datos en
reposo (bases de datos, volumes, backups). La rotacion periodica de estas claves debe
automatizarse en el pipeline de infraestructura.

### Criptografia Asimetrica

En 1976, Whitfield Diffie y Martin Hellman publicaron el concepto de criptografia de
clave publica, que resuelve el problema de distribucion de claves. Cada entidad posee
un par de claves matematicamente relacionadas: una clave publica (que puede difundirse
libremente) y una clave privada (que jamas debe revelarse).

Para cifrar un mensaje al receptor A, el emisor utiliza la clave publica de A. Solo A
puede descifrar el mensaje, ya que es el unico poseedor de su clave privada. Las claves
se generan a partir del producto de numeros primos grandes; derivar la clave privada a
partir de la publica es computacionalmente inviable con los recursos actuales.

Los algoritmos de clave publica mas utilizados son RSA (basado en factorizacion),
ElGamal y DH (basados en logaritmo discreto). Su principal desventaja es el coste
computacional, mayor que el de los algoritmos simetricos. Por ello, en la practica se
usa criptografia hibrida: la clave simetrica de sesion se intercambia usando criptografia
asimetrica, y el cifrado de los datos se realiza con la clave simetrica.

Aplicacion SRE: TLS utiliza criptografia asimetrica para el handshake inicial (negociacion
de clave de sesion) y simetrica para el cifrado del canal. La gestion del ciclo de vida de
certificados TLS debe estar completamente automatizada (renovacion, monitorizacion de
caducidad, rotacion sin tiempo de inactividad).

### Funciones Hash (Resumen)

Las funciones hash son funciones de un solo sentido que asocian a cada documento un
valor de longitud fija (el digest o resumen). Sus propiedades esenciales son: resistencia
a colisiones (es computacionalmente inviable encontrar dos documentos con el mismo
hash) e irreversibilidad (no es posible reconstruir el documento original a partir del hash).

Los algoritmos mas utilizados son SHA-256, SHA-512 y SHA-3. MD5 y SHA-1 se
consideran inseguros para propositos criptograficos debido a vulnerabilidades conocidas.

Aplicacion SRE: las funciones hash se usan para verificar la integridad de artefactos
(checksums de imagenes Docker, paquetes de software), para almacenar contrasenas de
forma segura (bcrypt, Argon2 internamente usan hashing iterativo) y para construir
cadenas de confianza en PKI y blockchain.

### Firma Digital

La firma digital es el mecanismo que proporciona autenticidad, integridad y no repudio
en el mundo digital. Su proceso es:

1. Se calcula el hash del documento (por ejemplo, con SHA-256).
2. El hash se cifra con la clave PRIVADA del firmante.
3. El resultado es la firma digital, que se adjunta al documento.

Para verificar la firma:

1. Se descifra la firma con la clave PUBLICA del firmante, obteniendo el hash original.
2. Se calcula el hash del documento recibido.
3. Si ambos hashes coinciden, la firma es valida y el documento no ha sido alterado.

La firma digital difiere de la firma manuscrita en un aspecto fundamental: dos documentos
distintos firmados por la misma persona producen firmas digitales distintas, ya que el
hash de cada documento es unico.

Aplicacion SRE: la firma de artefactos (imagenes de contenedor, binarios, paquetes) en
pipelines CI/CD garantiza la integridad de la cadena de suministro de software. Herramientas
como Cosign (Sigstore) automatizan este proceso para imagenes OCI.

### Certificado Digital

Un certificado digital (estandar X.509) es un documento electronico que vincula una
identidad (nombre, email, organizacion) con una clave publica, mediante la firma
criptografica de una Autoridad Certificadora (CA) de confianza. Los campos principales
son: version, numero de serie, algoritmo de firma, emisor (CA), periodo de validez,
titular (subject), clave publica, uso de clave y firma digital de la CA.

La confianza en un certificado se deriva de la confianza en quien lo ha firmado. Esta
estructura jerarquica es la base de la cadena de confianza: el cliente confia en la CA
raiz, la CA raiz ha firmado el certificado del servidor, por lo tanto el cliente confia en
el servidor.

Aplicacion SRE: los certificados TLS de servicios web deben renovarse antes de su
caducidad. Herramientas como cert-manager (Kubernetes) o AWS Certificate Manager
automatizan completamente la emision, renovacion y distribucion de certificados.

### Infraestructura de Clave Publica (PKI)

La PKI (Public Key Infrastructure) es el conjunto de hardware, software, politicas y
procedimientos necesarios para gestionar certificados digitales y claves publicas. Sus
componentes son:

- Autoridad Certificadora (CA): entidad de confianza que emite y revoca certificados.
- Autoridad de Registro (RA): verifica la identidad de los solicitantes antes de que la
  CA emita el certificado.
- Repositorio de certificados: almacena certificados emitidos y listas de revocacion (CRL).
- Lista de Revocacion de Certificados (CRL) y OCSP: mecanismos para invalidar
  certificados antes de su caducidad.

En Espana, la Real Casa de la Moneda y Timbre (FNMT) actua como CA raiz para los
certificados de ciudadanos utilizados en tramites con la Administracion Publica.

Aplicacion SRE: una PKI interna permite emitir certificados TLS mutuamente autenticados
(mTLS) para la comunicacion segura entre microservicios, sin depender de CAs publicas
y con pleno control sobre el ciclo de vida de los certificados.

---

## 2. Objetivos

### Objetivo General

Desarrollar las competencias tecnicas necesarias para implementar, automatizar y operar
sistemas criptograficos y de identificacion digital en entornos de infraestructura
reproducible, aplicando principios de ingenieria de fiabilidad de sitios (SRE) para
minimizar el riesgo operativo derivado de procesos criptograficos manuales o no
reproducibles.

### Objetivos Especificos

1. Comprender y aplicar los fundamentos teoricos de la criptografia simetrica, asimetrica
   y las funciones hash en el contexto de la seguridad de infraestructuras.

2. Implementar y automatizar la generacion de pares de claves asimetricas RSA 4096
   mediante GnuPG en modo no interactivo, usando archivos de parametros y el modo
   batch.

3. Demostrar el proceso completo de cifrado y descifrado simetrico con GnuPG
   (AES-256), verificando la integridad mediante funciones hash.

4. Generar, exportar, importar y gestionar certificados de revocacion de forma
   automatizada, aplicando mejores practicas del ciclo de vida de claves.

5. Implementar la firma digital de documentos mediante multiples modalidades (clearsign,
   detached, binary) y verificar la validez de firmas, incluyendo la deteccion de
   manipulaciones.

6. Instalar y configurar una Autoridad Certificadora (CA) raiz utilizando OpenSSL,
   emitiendo certificados de usuario con cadena de confianza verificable.

7. Gestionar el ciclo de vida completo de un certificado X.509: solicitud (CSR), emision,
   verificacion e instalacion, y revocacion con actualizacion de CRL.

8. Comprender el modelo conceptual del cifrado de correo electronico mediante
   certificados digitales (S/MIME), incluyendo firma y cifrado de mensajes.

9. Garantizar la reproducibilidad total del entorno de laboratorio mediante Docker y
   Docker Compose, de modo que cualquier operador pueda replicar exactamente el
   mismo entorno.

10. Aplicar principios SRE al diseño del laboratorio: no interactividad, idempotencia,
    trazabilidad mediante salidas estandar y gestion del error con codigos de salida
    explicitos.

---

## 3. Justificacion

### Por que la automatizacion es critica en operaciones criptograficas

Los procesos criptograficos manuales son inherentemente propensos al error humano.
La generacion de claves con parametros incorrectos, la omision del certificado de
revocacion, o el olvido de renovar un certificado TLS antes de su caducidad son causas
reales y frecuentes de incidentes de seguridad. La automatizacion elimina esta clase de
errores al codificar los parametros correctos en scripts versionados y revisados.

En SRE, la automatizacion es un principio fundamental del trabajo de reduccion de
toil (trabajo manual, repetitivo y sin valor duradero). Gestionar certificados de forma
manual en una infraestructura de cientos o miles de servicios no es escalable; es
necesario automatizar la emision, renovacion, distribucion y revocacion.

### Por que la reproducibilidad es obligatoria en SRE

Un entorno reproducible es aquel que puede recrearse exactamente a partir de su
definicion (codigo, configuracion, dependencias), independientemente de quien lo
ejecute y cuando. En SRE, la reproducibilidad es un requisito para la fiabilidad:
si el entorno de laboratorio, pre-produccion y produccion difieren, los tests y
validaciones pierden valor.

La contenedorizacion con Docker garantiza que las herramientas criptograficas
(GnuPG, OpenSSL) tienen exactamente la misma version y configuracion en todos
los entornos. El versionado de scripts en Git proporciona trazabilidad historica de
todos los cambios en los procedimientos operativos.

### Riesgos de los procesos criptograficos manuales

Los principales riesgos de los procesos manuales son:

- Generacion de claves con parametros debiles (longitud insuficiente, algoritmos obsoletos).
- Reutilizacion de claves entre entornos distintos (desarrollo, produccion).
- Almacenamiento inseguro de claves privadas (texto plano, repositorios de codigo).
- Caducidad no detectada de certificados, causando interrupciones del servicio.
- Ausencia de certificados de revocacion preparados, impidiendo revocar claves
  comprometidas.
- Procesos no documentados dependientes del conocimiento de una sola persona.

### Importancia de la gestion del ciclo de vida de claves

La gestion del ciclo de vida (Key Lifecycle Management) incluye generacion, distribucion,
almacenamiento, rotacion, revocacion y destruccion segura de claves. En una
infraestructura moderna, este ciclo debe estar completamente automatizado y auditado.
La rotacion periodica de claves limita el impacto de un compromiso: si una clave se
filtra, la ventana de exposicion esta acotada al periodo de rotacion. La automatizacion
de la rotacion, sin impacto en la disponibilidad del servicio, es una de las tareas mas
exigentes y valoradas en SRE de seguridad.

---

## 4. Casos Practicos

### Caso Practico 1: Cifrador de Polybios

El cifrador de Polybios (siglo II a.C.) es el primer cifrador por sustitucion documentado.
Reemplaza cada letra del alfabeto por el par de coordenadas (fila, columna) de su
posicion en una tabla de 5x5. El par puede expresarse como letras o como numeros.

```
Tabla de Polybios:
    1  2  3  4  5
1   A  B  C  D  E
2   F  G  H  IJ K
3   L  M  N  O  P
4   Q  R  S  T  U
5   V  W  X  Y  Z
```

La letra E se codifica como 15 (fila 1, columna 5). La letra S se codifica como 43.
I y J comparten la posicion 24 (compromiso por el tamano de la tabla).

Ejemplo: HELLO = 23 15 31 31 34

Relevancia SRE: los fundamentos de sustitucion y transposicion son la base conceptual
de los algoritmos modernos de cifrado en bloque (AES opera sobre sustitucion y
permutacion). Comprender los principios clasicos facilita la comprension de los modernos.

Ejecutar: `fish /workspace/scripts/pc1-polybius-cipher.fish`

### Caso Practico 2: Cifrado Simetrico con GnuPG

El cifrado simetrico con GnuPG utiliza el algoritmo AES-256 para cifrar un documento
con una frase de paso compartida. El mismo secreto es necesario para cifrar y descifrar.

Comandos clave:

- `gpg --symmetric --cipher-algo AES256` para cifrar.
- `gpg --decrypt` para descifrar.
- `--armor` para salida en formato ASCII (apto para email).
- `--batch --pinentry-mode loopback --passphrase` para operacion no interactiva.

El script ademas verifica la integridad comparando el hash SHA-256 del archivo original
con el del archivo descifrado.

Relevancia SRE: el cifrado de datos en reposo (backups, snapshots de base de datos)
usa frecuentemente cifrado simetrico. La frase de paso debe almacenarse en un gestor
de secretos, nunca en texto plano en el script.

Ejecutar: `fish /workspace/scripts/pc2-symmetric-encryption.fish`

### Caso Practico 3: Generacion de Par de Claves Asimetricas

Se genera un par de claves RSA 4096 bits de forma completamente no interactiva usando
el archivo `keyparams.conf`. El par incluye una clave principal y una subclave para
cifrado/firma.

Parametros del archivo keyparams.conf:

- `Key-Type: RSA` con `Key-Length: 4096`
- Caducidad de 1 ano (`Expire-Date: 1y`)
- `Passphrase` definida para automatizacion
- `%commit` para finalizar sin intervencion

Ejecutar: `fish /workspace/scripts/pc3-key-generation.fish`

### Caso Practico 4: Certificado de Revocacion

Un certificado de revocacion debe generarse INMEDIATAMENTE despues de crear el par
de claves. Permite informar a otros usuarios de que la clave publica ya no debe usarse,
incluso si se pierde la frase de paso o la clave privada queda comprometida.

Una clave publica revocada puede seguir usandose para verificar firmas antiguas, pero
no para cifrar nuevos datos.

Los codigos de razon de revocacion son: 0 (sin razon), 1 (clave comprometida),
2 (clave reemplazada), 3 (clave en desuso).

Ejecutar: `fish /workspace/scripts/pc4-revocation-certificate.fish`

### Caso Practico 5: Intercambio de Claves con GPG

Demuestra el flujo completo de intercambio de claves publicas entre dos entidades:
exportacion de la clave publica, importacion al anillo de claves del receptor, cifrado
de un mensaje para el receptor (usando su clave publica) y descifrado por el receptor
(usando su clave privada).

Este caso resuelve el problema de distribucion que hace inviable la criptografia
simetrica a escala: cada usuario solo necesita un par de claves, independientemente
del numero de interlocutores.

Ejecutar: `fish /workspace/scripts/pc5-key-exchange.fish`

### Caso Practico 6: Firma Digital de un Documento

Se demuestran las tres modalidades de firma digital con GPG:

1. `--clearsign`: el contenido del documento es legible en texto plano, con la firma
   adjunta al final. Util para correo electronico y documentos de texto.

2. `--detach-sign (-b)`: la firma se almacena en un archivo separado. Util para firmar
   binarios, ejecutables o archivos comprimidos sin modificarlos.

3. `--sign (-s)`: documento y firma se comprimen en un unico archivo binario.

El script ademas demuestra la deteccion de manipulacion: al modificar el contenido de
un documento firmado, la verificacion de la firma falla, lo que prueba que la integridad
ha sido violada.

Ejecutar: `fish /workspace/scripts/pc6-digital-signature.fish`

### Caso Practico 7: Instalacion de una Autoridad Certificadora

Se instala una CA raiz independiente equivalente a la del libro de texto, pero usando
OpenSSL en lugar de los Servicios de Certificados de Windows. Se crea la estructura
de directorios de la PKI, se genera la clave privada de la CA (RSA 4096, cifrada con
AES-256), se emite el certificado autofirmado de la CA (valido 10 anos) y se genera
la CRL inicial.

La CA creada (SiTourCA) es funcionalmente equivalente a la del caso practico del libro:
puede emitir certificados a empleados de la organizacion para firma de documentos y
correo electronico cifrado.

Ejecutar: `bash /workspace/scripts/pc7-certificate-authority.sh`

### Caso Practico 8: Solicitud y Revocacion de Certificados

Se demuestra el ciclo de vida completo de un certificado X.509:

1. El usuario (stella) genera su clave privada RSA 4096.
2. Stella crea una Solicitud de Firma de Certificado (CSR) con su informacion.
3. La CA firma el CSR y emite el certificado (valido 1 ano).
4. El certificado se verifica contra la CA.
5. Se exporta en formato PKCS#12 (bundle cert + clave) para importar en cliente de correo.
6. El certificado se revoca (razon: keyCompromise).
7. Se actualiza la CRL y se verifica que el certificado revocado ya no es valido.

El archivo PKCS#12 generado es el equivalente al certificado que Stella instala en
Internet Explorer en el caso practico del libro.

Ejecutar: `bash /workspace/scripts/pc8-certificate-request.sh`

### Caso Practico 9: Cifrado de Correo Electronico con Certificado Digital

Explicacion conceptual del estandar S/MIME (Secure/Multipurpose Internet Mail
Extensions) para firma y cifrado de correo electronico usando certificados X.509.
Incluye diagramas del proceso de firma, proceso de cifrado, cadena de confianza PKI,
comandos OpenSSL para operaciones S/MIME desde linea de comandos y comparativa
entre GPG/OpenPGP y S/MIME.

Ver: `cat /workspace/scripts/pc9-secure-email.md`

---

## 5. Mejoras SRE Mas Alla del Libro

Esta seccion presenta practicas operativas avanzadas que trascienden el alcance del
libro de texto y constituyen el estandar actual en entornos de produccion.

### Politicas de Rotacion de Claves

La rotacion periodica de claves es un control preventivo fundamental. Si una clave se
filtra y no se detecta de inmediato, la rotacion limita la ventana de exposicion. Las
politicas recomendadas son: claves de sesion TLS con Perfect Forward Secrecy (PFS)
para que cada sesion use una clave efimera; claves simetricas de datos en reposo con
rotacion anual como minimo; certificados TLS con validez maxima de 90 dias (los CAs
publicos impondran limites aun mas cortos en 2025). La rotacion debe ser automatica
y sin tiempo de inactividad (zero-downtime rotation).

### Almacenamiento Offline de Revocacion

Los certificados de revocacion de GPG y las claves privadas de CA raiz deben
almacenarse offline, en medios cifrados y fisicamente seguros (cajas de seguridad,
HSM offline). En produccion, la clave privada de la CA raiz jamas debe estar en un
sistema conectado a la red. El proceso de emision de certificados se delega a CAs
intermedias cuyas claves si pueden estar online.

### Estrategias de Backup de Material Criptografico

El material criptografico requiere una estrategia de backup diferenciada: las claves
privadas deben backupearse en forma cifrada, con acceso restringido y auditado. Se
recomienda la estrategia M-de-N (por ejemplo, dividir la clave en 5 fragmentos,
requiriendo 3 para reconstruirla, usando Shamir's Secret Sharing). Los backups deben
probarse regularmente: un backup que no se ha restaurado es un backup no verificado.

### Gestion de Secretos

En entornos de produccion, las frases de paso y claves nunca deben estar en texto plano
en scripts o variables de entorno. Las soluciones estandar son: HashiCorp Vault (gestion
de secretos con auditoria, politicas y rotacion automatica), AWS Secrets Manager / Azure
Key Vault / GCP Secret Manager (servicios gestionados en cloud), SOPS (cifrado de
archivos de configuracion para GitOps) y age/gpg con encriptacion en repositorio. La
inyeccion de secretos en tiempo de ejecucion (init containers, sidecar agents) es
preferible a almacenarlos en imagenes Docker o variables de entorno.

### Firma de Artefactos en CI/CD

La cadena de suministro de software es un vector de ataque creciente. Cada artefacto
producido por un pipeline CI/CD (imagen Docker, binario, paquete) debe firmarse
criptograficamente para garantizar su proveniencia e integridad. Las herramientas
actuales incluyen: Cosign (Sigstore) para imagenes OCI con transparencia publica,
in-toto para atestiguar cada paso del pipeline, Notary v2 para firmas de contenido en
registros OCI, y GPG/PGP para paquetes de distribuciones Linux (apt, yum). La
verificacion de firmas debe ser obligatoria en el proceso de despliegue.

### Integridad de la Cadena de Suministro

La integridad de la cadena de suministro (supply chain security) va mas alla de firmar
artefactos: incluye la verificacion de las dependencias del software (SBOMs - Software
Bill of Materials), la reproducibilidad de los builds (reproducible builds), la verificacion
de la procedencia de las imagenes base, y la politica de admision en Kubernetes que
rechaza imagenes no firmadas. El framework SLSA (Supply Chain Levels for Software
Artifacts) define niveles de madurez para estas practicas.

### Verificacion de Distribucion Segura de Claves

Al recibir una clave publica, debe verificarse su autenticidad mediante un canal
out-of-band: comparacion de la huella digital (fingerprint) por telefono, presencialmente
o a traves de un canal secundario de confianza. El modelo de confianza de GPG (Web
of Trust) permite que terceros avalen la autenticidad de una clave mediante su propia
firma. En PKI empresarial, la autenticidad se garantiza por la cadena de confianza hasta
la CA raiz.

### Alineacion con Infrastructure as Code

Toda la configuracion de la PKI (estructura de directorios, parametros de la CA,
politicas de emision) debe expresarse como codigo (IaC), versionada en Git y aplicada
de forma reproducible. Herramientas como Terraform (provider Vault, provider TLS),
Ansible (modulos openssl\_\*) o scripts Bash/Fish como los de este repositorio permiten
tratar la infraestructura criptografica con el mismo rigor que cualquier otro componente
de infraestructura. El principio GitOps aplica: el estado deseado del sistema se declara
en el repositorio y se reconcilia automaticamente.

### Justificacion de la Automatizacion

La automatizacion de operaciones criptograficas no es solo una cuestion de eficiencia;
es un requisito de seguridad. Los procesos manuales no escalan, son propensos al error
y producen desviaciones de configuracion (configuration drift) que son dificiles de
detectar y corregir. En SRE, el objetivo es que cualquier operacion criptografica
rutinaria (generacion de claves, renovacion de certificados, rotacion de secretos) sea
ejecutable por cualquier miembro del equipo, sin conocimiento previo, simplemente
ejecutando un comando documentado. El toil resultante de la gestion manual de
certificados y claves en una infraestructura de escala real es una de las principales
causas de deuda tecnica en equipos de operaciones de seguridad.

---

## Estructura del Repositorio

```
crypto-lab/
|
|-- Dockerfile              # Imagen reproducible sobre debian:stable-slim
|-- compose.yml             # Definicion del servicio crypto-lab
|-- README.md               # Instrucciones operativas (en espanol)
|-- keyparams.conf          # Parametros no interactivos para GPG genkey
|
|-- scripts/
|   |-- pc1-polybius-cipher.fish        # Cifrador de Polybios
|   |-- pc2-symmetric-encryption.fish   # Cifrado simetrico AES-256 con GPG
|   |-- pc3-key-generation.fish         # Generacion par de claves RSA 4096
|   |-- pc4-revocation-certificate.fish # Certificado de revocacion GPG
|   |-- pc5-key-exchange.fish           # Intercambio de claves publicas GPG
|   |-- pc6-digital-signature.fish      # Firma digital de documentos
|   |-- pc7-certificate-authority.sh    # Instalacion CA raiz con OpenSSL
|   |-- pc8-certificate-request.sh      # Solicitud, emision y revocacion X.509
|   `-- pc9-secure-email.md             # Correo cifrado S/MIME (explicacion conceptual)
```

---

_Guia generada en base al contenido del libro "Seguridad Informatica", Unidad 4:
Sistemas de identificacion. Criptografia. Paginas 81-106._
