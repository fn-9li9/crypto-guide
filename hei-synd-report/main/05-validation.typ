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

// Pendiente: captura de terminal con la ejecucion de
// fish /workspace/scripts/pc4-revocation-certificate.fish
// Incluir: primeras lineas del certificado de revocacion generado,
// advertencias de seguridad mostradas por el script.

// ============================================================
// CP5 - Intercambio de Claves
// ============================================================

== CP5: Intercambio de Claves con GPG

// Pendiente: captura de terminal con la ejecucion de
// fish /workspace/scripts/pc5-key-exchange.fish
// Incluir: exportacion de clave publica, importacion al anillo,
// mensaje cifrado (primeras lineas del .asc), descifrado exitoso.

// ============================================================
// CP6 - Firma Digital
// ============================================================

== CP6: Firma Digital de un Documento

// Pendiente: captura de terminal con la ejecucion de
// fish /workspace/scripts/pc6-digital-signature.fish
// Incluir: firma clearsign (documento + firma), verificacion exitosa,
// demostracion de deteccion de manipulacion (BAD signature).

// ============================================================
// CP7 - Autoridad Certificadora
// ============================================================

== CP7: Instalacion de la Autoridad Certificadora

// Pendiente: captura de terminal con la ejecucion de
// bash /workspace/scripts/pc7-certificate-authority.sh
// Incluir: estructura de directorios creada, datos del certificado CA
// (Subject, Issuer, Not Before/After, algoritmo), huellas digitales.

// ============================================================
// CP8 - Solicitud y Revocacion
// ============================================================

== CP8: Solicitud y Revocacion de Certificados

// Pendiente: captura de terminal con la ejecucion de
// bash /workspace/scripts/pc8-certificate-request.sh
// Incluir: CSR generado, certificado emitido (datos principales),
// verificacion de cadena OK, contenido de index.txt antes y despues
// de la revocacion, resultado de verificacion con -crl_check.

// ============================================================
// CP9 - Correo Electronico Cifrado
// ============================================================

== CP9: Cifrado de Correo Electronico con Certificado Digital

// Pendiente: este caso practico es una guia conceptual (Markdown).
// Incluir: fragmento de la salida de los comandos OpenSSL smime
// ejecutados manualmente en el contenedor para validar la guia,
// o captura del contenido del archivo pc9-secure-email.md con
// anotaciones sobre los comandos mas relevantes.
