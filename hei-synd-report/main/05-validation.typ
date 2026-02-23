#import "@preview/hei-synd-report:0.1.1": *
#import "../metadata.typ": *
#pagebreak()

= Resultados

#option-style(type: option.type)[
  Este capitulo documenta la ejecucion de cada uno de los nueve casos practicos dentro
  del entorno Docker. Para cada caso se presenta: el comando de ejecucion, la salida
  relevante del terminal con anotaciones explicativas, y un analisis de los resultados
  obtenidos en relacion con los conceptos teoricos del marco teorico.

  Elementos clave por caso practico:
  - *Comando ejecutado* y condiciones previas necesarias (orden de ejecucion).
  - *Salida del terminal* con las partes mas significativas destacadas.
  - *Verificacion de correctitud*: hashes comparados, firmas validadas, certificados
    emitidos y revocados correctamente.
  - *Observaciones*: comportamientos destacables, mensajes de advertencia esperados,
    y su interpretacion en el contexto criptografico.
]

// ============================================================
// CP1 - Cifrador de Polybios
// ============================================================


== CP1: Cifrador de Polybios

El primer caso practico implementa el cifrador de sustitucion de Polybios en Fish shell.
La tabla de 5x5 asigna a cada letra del alfabeto un par de coordenadas (fila, columna),
reemplazando cada caracter por dos digitos. Las letras I y J comparten la posicion 24,
compromiso clasico del cifrador para acomodar el alfabeto latino en una cuadricula de
25 celdas.

#figure(
  image("../resources/img/cp-1.png", width: 100%),
  caption: [Ejecucion del cifrador de Polybios sobre el mensaje de ejemplo],
)

La ejecucion sobre el mensaje `POLYBIOS CIPHER IS THE FIRST SUBSTITUTION CIPHER`
produce los siguientes resultados:

*Codificacion estandar* (espacios descartados):

```
35 34 31 54 12 24 34 43  13 24 35 23 15 42  24 43  44 23 15
21 24 42 43 44  43 45 12 43 44 24 44 45 44 24 34 33  13 24 35 23 15 42
```

*Codificacion con espacios* (espacio codificado como `00`):

```
35 34 31 54 12 24 34 43 00 13 24 35 23 15 42 00 24 43 00 44 23 15 00
21 24 42 43 44 00 43 45 12 43 44 24 44 45 44 24 34 33 00 13 24 35 23 15 42
```

La decodificacion del segundo resultado reproduce exactamente el mensaje original,
incluidos los espacios entre palabras, verificando la correctitud del algoritmo en ambas
direcciones. La letra P se codifica como `35` (fila 3, columna 5); la letra O como `34`
(fila 3, columna 4); la letra L como `31` (fila 3, columna 1).

Este cifrador, desarrollado en el siglo II a.C., es el precursor directo de los modernos
cifrados de sustitucion polialfabetica y de los codigos binarios: la idea de representar
un simbolo mediante su posicion en una tabla bidimensional subyace en la codificacion
ASCII y en las tablas de sustitucion (*S-boxes*) de AES.

// ============================================================
// CP2 - Cifrado Simetrico
// ============================================================

== CP2: Cifrado Simetrico con GnuPG

El segundo caso practico demuestra el ciclo completo de cifrado simetrico AES-256
con GnuPG: creacion del documento, cifrado en formato binario y ASCII-armored,
descifrado y verificacion de integridad mediante SHA-256. En el cifrado simetrico,
la misma frase de paso se usa para cifrar y descifrar, lo que implica que emisor y
receptor deben haberla acordado previamente por un canal seguro.

#figure(
  image("../resources/img/cp2-1.png", width: 100%),
  caption: [Ejecucion del cifrado simetrico AES-256 con GnuPG],
)

La ejecucion del script crea el archivo `secret_document.txt` y produce cuatro
artefactos en el directorio `/workspace/samples/`:

- `secret_document.txt.gpg` --- archivo cifrado en formato binario (261 bytes
  frente a los 222 bytes del original, overhead del encabezado GPG).
- `secret_document.asc` --- mismo contenido cifrado en formato ASCII-armored,
  transportable por canales que solo admiten texto plano como el correo electronico.
- `secret_document_decrypted.txt` --- resultado del descifrado, usado para la
  verificacion de integridad.

El formato ASCII-armored comienza con la cabecera estandar PGP:

```
-----BEGIN PGP MESSAGE-----
jA0ECQMKxjNec2npPzn20sAzAepWyLNqT7xFNJpqRtSKvnrG7g8x...
```

Para ilustrar que el cifrado produce datos binarios ilegibles, la segunda imagen
muestra el contenido del archivo `secret_document.txt.gpg` visualizado en bruto:

#figure(
  image("../resources/img/cp-2-2.png", width: 100%),
  caption: [Contenido binario de secret\_document.txt.gpg: los datos originales son completamente ininteligibles sin la frase de paso],
)

La verificacion de integridad compara el hash SHA-256 del archivo original con el
del archivo descifrado. Si el cifrado y descifrado se han realizado correctamente,
ambos hashes deben ser identicos:

```
INTEGRITY CHECK: PASSED - Files are identical.
```

Este resultado confirma que AES-256 es un cifrado sin perdida: el proceso
cifrado-descifrado reproduce el documento original bit a bit. La comparacion de
hashes es ademas el mecanismo que GnuPG usa internamente para detectar
corrupcion o manipulacion del archivo cifrado antes de entregarlo al receptor.

El script señala al final la limitacion fundamental del cifrado simetrico: la frase
de paso `fn-stella-sre` esta definida en texto plano en el script, lo que seria
inaceptable en produccion. El caso practico 5 aborda como la criptografia asimetrica
elimina este problema de distribucion de secretos.

// ============================================================
// CP3 - Generacion de Par de Claves
// ============================================================

== CP3: Generacion de Par de Claves Asimetricas

El tercer caso practico genera un par de claves RSA 4096 de forma completamente
no interactiva usando el archivo `keyparams.conf`. La criptografia asimetrica resuelve
el problema de distribucion de claves de la criptografia simetrica: cada entidad
necesita un unico par de claves independientemente del numero de interlocutores,
y la clave publica puede difundirse libremente sin comprometer la seguridad.

Antes de generar el nuevo par, el script verifica el estado actual del anillo de claves:

#figure(
  image("../resources/img/cp-3-1.png", width: 100%),
  caption: [Estado del anillo de claves antes de la generacion],
)

En este caso el anillo ya contiene dos pares previos de ejecuciones anteriores del
script, lo que demuestra que el volumen `gnupg-data` persiste correctamente el
material criptografico entre sesiones del contenedor.

La generacion del nuevo par utiliza el archivo `keyparams.conf`, que codifica todos
los parametros de forma declarativa: tipo RSA, longitud 4096 bits, caducidad de
1 año, identidad del titular y frase de paso. El parametro `%commit` finaliza la
generacion sin intervencion del usuario:

#figure(
  image("../resources/img/cp-3-2.png", width: 100%),
  caption: [Generacion del par de claves RSA 4096 usando keyparams.conf en modo batch],
)

GPG genera automaticamente un certificado de revocacion de emergencia almacenado
en `/root/.gnupg/openpgp-revocs.d/CD9C63A7...FF0090.rev`. Tras la generacion, el
anillo contiene tres pares; el recien creado tiene la huella:
```
CD9C 63A7 C075 0BAD D9F7  B323 EE73 CC88 59FF 0090
```

El listado conjunto de claves publicas y privadas confirma la estructura del par: una
clave principal `sec` con capacidades `[SCEAR]` (Sign, Certify, Encrypt, Authenticate,
pRoots) y una subclave `ssb` con capacidades `[SEA]`:

#figure(
  image("../resources/img/cp-3-3.png", width: 100%),
  caption: [Listado de claves publicas (pub) y privadas (sec) en el anillo tras la generacion],
)

La clave publica se exporta en formato ASCII-armored al archivo
`/workspace/samples/cryptolab_public.asc` (183 lineas). Las primeras lineas del
bloque exportado muestran la cabecera estandar OpenPGP seguida del material de
clave codificado en base64:

#figure(
  image("../resources/img/cp-3-4.png", width: 100%),
  caption: [Exportacion de la clave publica en formato ASCII-armored],
)
```
-----BEGIN PGP PUBLIC KEY BLOCK-----

mQINBGmbdUUBEACTnJnEBkFjqhh8wkEBSjfn5ZMqab/nv7XwC0ngbxxSDzsqASig
dAb1LRMdiOl2CdEN+6OmQzHT/kmt1ckbAjbSYQTccEI7aCYAliJQy30Lz/+uCSQs
...
=tltW
-----END PGP PUBLIC KEY BLOCK-----
```

Este archivo es la clave publica que puede distribuirse libremente: enviarse por
correo electronico, publicarse en un servidor de claves PGP o incluirse en un
repositorio Git. Cualquier persona que disponga de este bloque puede cifrar mensajes
que solo el poseedor de la clave privada correspondiente podra descifrar.

La huella digital de 40 caracteres hexadecimales es el identificador unico del par de
claves. En un entorno real, esta huella debe verificarse con el propietario por un canal
fuera de banda (telefono, presencialmente) antes de usar la clave publica para cifrar
informacion sensible, garantizando que la clave no ha sido sustituida por un atacante.

// ============================================================
// CP4 - Certificado de Revocacion
// ============================================================

== CP4: Certificado de Revocacion

El cuarto caso practico genera un certificado de revocacion para la clave RSA 4096
creada en CP3. Un certificado de revocacion es un documento firmado criptograficamente
que, al publicarse, notifica a todos los usuarios que la clave publica asociada ya no debe
usarse para cifrar nuevos mensajes. Su generacion inmediatamente despues de crear el
par de claves es una practica de seguridad fundamental: si la clave privada queda
comprometida o se pierde la frase de paso, el certificado permite revocarla incluso sin
acceso a la clave privada.

#figure(
  image("../resources/img/cp-4-1.png", width: 100%),
  caption: [Generacion del certificado de revocacion para la clave CD9C...0090],
)

El script identifica la clave principal por su fingerprint completo (no por email, para
evitar ambiguedad cuando existen multiples claves con el mismo uid), y usa `expect`
para conducir la sesion interactiva de `gpg --gen-revoke` via un pseudo-TTY real,
ya que GPG 2.4 rechaza el modo batch para este comando. El certificado generado
se almacena en `/workspace/samples/revocation/revocation_cert.asc` (942 bytes) y
comienza con la cabecera estandar:
```
-----BEGIN PGP PUBLIC KEY BLOCK-----
Comment: This is a revocation certificate
iQJbBCABCgBFFiEEzZxjp8B1C63Z97Mj7nPMiFn/AJAFAmmbhkknHQBQcmVjYXV0
...
-----END PGP PUBLIC KEY BLOCK-----
```

El script documenta ademas los cuatro codigos de razon de revocacion definidos en el
estandar OpenPGP: 0 (sin razon especificada, uso precautorio), 1 (clave comprometida),
2 (clave reemplazada por una nueva) y 3 (clave en desuso). En este caso se usa el
codigo 0 por tratarse de un certificado precautorio creado inmediatamente tras la
generacion del par.

Las advertencias de seguridad mostradas al final del script reflejan las mejores
practicas operativas: el certificado debe almacenarse en un medio cifrado offline
(USB cifrado, caja de seguridad fisica), ya que cualquier persona que lo obtenga
puede invalidar la clave publica publicandolo en un servidor de claves. A diferencia
de la clave privada, el certificado de revocacion no permite descifrar mensajes ni
firmar documentos: su unico efecto es anunciar que la clave ya no es de confianza.

Una propiedad importante del mecanismo de revocacion es que una clave publica
revocada conserva su capacidad de verificar firmas anteriores a la revocacion, pero
no puede usarse para cifrar nuevos mensajes. Esto garantiza la auditabilidad de
documentos firmados antes del compromiso de la clave.

// ============================================================
// CP5 - Intercambio de Claves
// ============================================================

== CP5: Intercambio de Claves con GPG

El quinto caso practico demuestra el flujo completo de intercambio de claves publicas
entre dos entidades simuladas (Alice y Bob) usando la clave RSA 4096 de Stella como
clave de laboratorio. El objetivo es evidenciar como la criptografia asimetrica resuelve
el problema de distribucion de claves que hace inviable la criptografia simetrica a escala.

#figure(
  image("../resources/img/cp-5-1.png", width: 100%),
  caption: [Exportacion de la clave publica de Alice e importacion al anillo de Bob],
)

Alice exporta su clave publica al archivo `alice_public.asc` mediante redireccion de
stdout (`gpg --armor --export > archivo`). Bob importa ese archivo a su anillo de
claves con `gpg --import`. GPG confirma que la clave ya existia en el anillo
(`not changed: 1`), lo que es el comportamiento esperado en un laboratorio donde
Alice y Bob comparten el mismo keyring. En un escenario real, Bob recibiria el archivo
`.asc` por correo electronico, servidor de claves PGP o cualquier canal, incluso uno
no seguro, porque la clave publica no es un secreto.

#figure(
  image("../resources/img/cp-5-2.png", width: 100%),
  caption: [Cifrado del mensaje por Bob y descifrado exitoso por Alice],
)

Bob cifra un mensaje de texto plano usando la clave publica de Alice con
`gpg --encrypt --recipient`. El resultado es un bloque PGP cifrado que solo Alice
puede descifrar:
```
-----BEGIN PGP MESSAGE-----
hQIMA7AEpVhj+tD6ARAAqaRGEdKVFx0mcr6ZSK1IbWqtXNNrb1E0kKbsvb9ayNsi
...
-----END PGP MESSAGE-----
```

Alice descifra el mensaje con su clave privada y la frase de paso. El contenido
recuperado es identico al original, confirmando que el ciclo cifrado-descifrado
asimetrico es correcto y sin perdida.

El resumen final del script cuantifica el problema que resuelve la criptografia asimetrica.
Con criptografia simetrica, 100 usuarios necesitarian 4950 claves compartidas distintas,
cada una intercambiada por un canal seguro previo. Con criptografia asimetrica, cada
usuario necesita un unico par de claves independientemente del numero de
interlocutores, y la clave publica puede distribuirse libremente por cualquier canal
sin comprometer la seguridad del sistema. Los servidores de claves publicos
(`keys.openpgp.org`, `keyserver.ubuntu.com`) actuan como directorios globales donde
cualquier usuario puede publicar y buscar claves publicas.

// ============================================================
// CP6 - Firma Digital
// ============================================================

== CP6: Firma Digital de un Documento

El sexto caso practico demuestra las tres modalidades de firma digital con GnuPG y
verifica la propiedad de integridad mediante una demostracion de deteccion de
manipulacion. Antes de firmar, el script calcula el hash SHA-256 del documento para
ilustrar que la firma opera sobre el resumen criptografico, no sobre el contenido
completo:
```
3c0ade405ae26545e91a8cd5a5e01a43e8114e23d4a572d00900ea0239b350c2  contract.txt
```

#figure(
  image("../resources/img/cp-6-1.png", width: 100%),
  caption: [Hash SHA-256 del documento y firma en modalidad clearsign],
)

*Modalidad 1 — `--clearsign`*: el contenido del documento permanece legible en texto
plano dentro del archivo `.asc`, con la firma PGP adjunta al final. Esta modalidad es
idonea para correo electronico y documentos que los destinatarios deben poder leer
sin software criptografico. El bloque firmado comienza con `-----BEGIN PGP SIGNED
MESSAGE-----` seguido del contenido original del contrato y termina con el bloque
`-----BEGIN PGP SIGNATURE-----`.

#figure(
  image("../resources/img/cp-6-2.png", width: 100%),
  caption: [Firma detached en archivo separado y firma binaria comprimida],
)

*Modalidad 2 — `--detach-sign`*: la firma se almacena en un archivo independiente
`contract.txt.sig`, sin modificar el documento original. Esta modalidad es la estandar
para firmar artefactos binarios (ejecutables, imagenes Docker, paquetes de software)
donde incrustar la firma alteraria el archivo. La verificacion requiere disponer de
ambos archivos: el documento y el `.sig`.

*Modalidad 3 — `--sign`*: documento y firma se comprimen en un unico archivo binario
`contract_signed.gpg`. El contenido no es legible directamente; se extrae y verifica
en un unico paso con `--decrypt`.

#figure(
  image("../resources/img/cp-6-3.png", width: 100%),
  caption: [Verificacion de firmas y demostracion de deteccion de manipulacion],
)

La verificacion de las dos primeras modalidades produce en ambos casos:
```
gpg: Good signature from "stella (fn-stella-sre) <stella.sre.inc@gmail.com>" [ultimate]
```

La demostracion de deteccion de manipulacion es la prueba mas relevante del caso
practico: se copia el archivo `contract_clearsigned.asc` a `contract_tampered.asc`
y se reemplaza la cadena `one year` por `ten years` en el contenido. Al verificar
el archivo manipulado, GPG detecta la discrepancia entre el hash firmado y el hash
del contenido alterado:
```
gpg: BAD signature from "stella (fn-stella-sre) <stella.sre.inc@gmail.com>" [ultimate]
```

Este resultado confirma empiricamente la propiedad de integridad de la firma digital:
cualquier modificacion del documento, por minima que sea, invalida completamente
la firma. El efecto avalancha de SHA-512 garantiza que incluso un cambio de un
solo caracter produce un hash completamente distinto, haciendo inviable que un
atacante modifique el contenido sin que la verificacion lo detecte.

Los cinco archivos generados en `/workspace/samples/signatures/` ilustran cada
artefacto del proceso: `contract.txt` (original), `contract_clearsigned.asc` (clearsign),
`contract.txt.sig` (firma detached), `contract_signed.gpg` (binario firmado) y
`contract_tampered.asc` (documento manipulado para la demostracion).

// ============================================================
// CP7 - Autoridad Certificadora
// ============================================================

== CP7: Instalacion de la Autoridad Certificadora

El septimo caso practico instala una Autoridad Certificadora raiz funcional equivalente
a la del libro de texto (Servicios de Certificados de Windows Server), implementada
con OpenSSL sobre Linux. A diferencia del procedimiento original basado en interfaces
graficas de Windows 2000, este script es completamente reproducible y ejecutable en
cualquier entorno con OpenSSL disponible.

#figure(
  image("../resources/img/cp-7-1.png", width: 100%),
  caption: [Creacion de la estructura de directorios PKI y generacion del openssl.cnf],
)

El script inicializa la estructura de directorios de la PKI en `/workspace/pki/ca/` con
los cinco componentes operativos de una CA: `certs/` para los certificados emitidos,
`private/` con permisos 700 para la clave privada, `newcerts/` para las copias
historicas de cada certificado emitido por numero de serie, `crl/` para las Listas de
Revocacion de Certificados, e `index.txt` como base de datos de certificados. El
archivo `openssl.cnf` se genera con dos politicas de certificacion: `policy_strict`
(que exige que los campos C, ST y O del CSR coincidan con los de la CA) y
`policy_loose` (que solo requiere el CN), junto con las extensiones X.509 v3
`v3_ca`, `usr_cert` y `server_cert`.

#figure(
  image("../resources/img/cp-7-2.png", width: 100%),
  caption: [Generacion de la clave privada RSA 4096, certificado autofirmado, CRL inicial y huellas digitales],
)

La clave privada de la CA se genera con RSA 4096 bits cifrada con AES-256 y
permisos 400. El certificado autofirmado tiene una validez de 3650 dias (10 anos),
lo que es estandar para CAs raiz que no dependen de una CA superior. Los datos
del certificado emitido son:
```
Issuer:  C=PE, ST=Lima, L=Lima, O=SiTour SA, OU=Division de certificados,
         CN=SiTourCA, emailAddress=stella.sre.inc@gmail.com
Subject: (identico al Issuer, por ser autofirmado)
Not Before: Feb 23 13:51:52 2026 GMT
Not After:  Feb 21 13:51:52 2036 GMT
```

La CRL inicial se genera vacia inmediatamente tras la instalacion de la CA, con un
periodo de validez de 30 dias. En produccion, la CRL debe regenerarse y publicarse
periodicamente antes de su caducidad para que los clientes puedan verificar el estado
de revocacion de los certificados emitidos.

Las huellas digitales del certificado CA se muestran en SHA-256 y SHA-1 para
permitir su verificacion fuera de banda. En un despliegue real, estas huellas se
distribuyen por un canal seguro separado (correo firmado, pagina web con TLS,
comunicacion presencial) para que los usuarios puedan confirmar que el certificado
CA que instalan en su almacen de confianza es el autentico y no ha sido sustituido:
```
SHA-256: FE:E4:CA:B1:34:F8:D0:A4:82:A6:CB:09:93:AE:96:CB:
         B9:FE:6F:F6:F2:91:0E:6B:15:C4:6B:AC:13:74:60:54
SHA-1:   2A:D6:88:4A:6A:93:78:F6:F2:0D:39:AF:63:40:5F:5C:CA:1A:23:9E
```

La carpeta `newcerts/` queda vacia al finalizar PC7, lo cual es el comportamiento
correcto: OpenSSL la pobla automaticamente con copias de cada certificado emitido
(nombradas `01.pem`, `02.pem`, etc.) cuando la CA firma solicitudes CSR en PC8.

// ============================================================
// CP8 - Solicitud y Revocacion
// ============================================================

== CP8: Solicitud y Revocacion de Certificados

El octavo caso practico demuestra el ciclo de vida completo de un certificado X.509:
desde la generacion de la clave privada del usuario hasta la revocacion y verificacion
del estado revocado mediante CRL. Este flujo es el equivalente automatizado del
procedimiento manual del libro de texto donde Fernando solicita un certificado a la
CA SiTourCA a traves de Internet Explorer.

#figure(
  image("../resources/img/cp-8-1.png", width: 100%),
  caption: [Verificacion de la CA instalada en PC7 como prerequisito],
)

El script verifica primero que la CA del caso practico 7 este operativa consultando
el certificado `ca.crt` y mostrando su subject. A continuacion ejecuta los siete
pasos del ciclo de vida.

#figure(
  image("../resources/img/cp-8-2.png", width: 100%),
  caption: [Step 1 --- Generacion de la clave privada RSA 4096 de Stella],
)

*Step 1*: Se genera la clave privada RSA 4096 de Stella cifrada con AES-256
y frase de paso `UserCertPass2026!`. El archivo se almacena con permisos 400
en `/workspace/pki/users/stella/stella.key`.

#figure(
  image("../resources/img/cp-8-3.png", width: 100%),
  caption: [Step 2 --- Creacion del CSR con los datos de identidad de Stella],
)

*Step 2*: Se crea la Solicitud de Firma de Certificado (CSR) con el subject
`/C=PE/ST=Lima/L=Lima/O=SiTour SA/OU=Ventas/CN=Stella`. El CSR contiene
la clave publica de Stella y su informacion de identidad, firmado con su clave
privada para demostrar posesion de la clave.

#figure(
  image("../resources/img/cp-8-4.png", width: 100%),
  caption: [Step 3 --- La CA SiTourCA firma el CSR y emite el certificado serie 01],
)

*Step 3*: La CA firma el CSR usando `policy_loose` y las extensiones `usr_cert`
(que habilitan `clientAuth` y `emailProtection`). El certificado emitido tiene
numero de serie `01`, validez de 365 dias y las extensiones X.509 v3 completas.
OpenSSL actualiza automaticamente `index.txt` y copia el certificado en
`newcerts/01.pem`.

#figure(
  image("../resources/img/cp-8-5.png", width: 100%),
  caption: [Step 4 --- Verificacion de la cadena de confianza contra la CA raiz],
)

*Step 4*: La verificacion de la cadena confirma que el certificado de Stella es
valido y esta firmado por SiTourCA:
```
/workspace/pki/users/stella/stella.crt: OK
```

#figure(
  image("../resources/img/cp-8-6.png", width: 100%),
  caption: [Step 5 --- Exportacion del bundle PKCS\#12 para importacion en cliente de correo],
)

*Step 5*: El bundle PKCS\#12 (`stella.p12`) agrupa el certificado, la clave privada
y la cadena CA en un unico archivo protegido por frase de paso. Este es el formato
que Thunderbird, Outlook y otros clientes de correo usan para importar identidades
digitales y habilitar S/MIME.

#figure(
  image("../resources/img/cp-8-7.png", width: 100%),
  caption: [Step 6 --- Revocacion del certificado y actualizacion de la CRL],
)

*Step 6*: El certificado se revoca con razon `keyCompromise`. La base de datos
`index.txt` registra el cambio de estado. La CRL actualizada lista el certificado
con numero de serie `01` como revocado:
```
Revoked Certificates:
    Serial Number: 01
        Revocation Date: Feb 23 14:02:18 2026 GMT
        CRL entry extensions:
            X509v3 CRL Reason Code: Key Compromise
```

El estado de `index.txt` antes de la revocacion era:
```
V  270223140218Z  01  unknown  /C=PE/ST=Lima/.../CN=Stella/...
```
Tras la revocacion, la entrada cambia de `V` (Valid) a `R` (Revoked).

#figure(
  image("../resources/img/cp-8-8.png", width: 100%),
  caption: [Step 7 --- Verificacion del estado revocado con CRL y tabla de codigos de razon],
)

*Step 7*: La verificacion con `-crl_check` confirma que el certificado ha sido
invalidado. OpenSSL devuelve `error 23: certificate revoked`, demostrando que
cualquier cliente que consulte la CRL rechazara este certificado:
```
error 23 at 0 depth lookup: certificate revoked
error /workspace/pki/users/stella/stella.crt: verification failed
```

La tabla de codigos de razon de revocacion (0-6) documenta los motivos
estandarizados por el RFC 5280, desde `keyCompromise` hasta `certificateHold`,
que permiten expresar con precision la causa de la invalidacion de un certificado.

// ============================================================
// CP9 - Correo Electronico Cifrado
// ============================================================

== CP9: Cifrado de Correo Electronico con Certificado Digital

// Pendiente: este caso practico es una guia conceptual (Markdown).
// Incluir: fragmento de la salida de los comandos OpenSSL smime
// ejecutados manualmente en el contenedor para validar la guia,
// o captura del contenido del archivo pc9-secure-email.md con
// anotaciones sobre los comandos mas relevantes.
