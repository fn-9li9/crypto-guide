#import "@preview/hei-synd-report:0.1.1": *
#import "../metadata.typ": *
#pagebreak()

= Desarrollo

== Contexto del Laboratorio

El laboratorio surge de la necesidad de trasladar los casos practicos del libro de texto
*Seguridad Informatica* (Unidad 4, paginas 81-106) desde entornos interactivos con
interfaces graficas ---Windows 2000 Server, Outlook Express, Internet Explorer--- a un
entorno moderno, completamente automatizado y reproducible. Los casos practicos
originales exigen la interaccion del usuario en cada paso: seleccionar opciones en
menus, introducir frases de paso en dialogos, hacer clic en botones de instalacion.

Esta interactividad es incompatible con los principios SRE de automatizacion y
reproducibilidad. Un procedimiento que requiere intervencion humana no puede
ejecutarse en un pipeline CI/CD, no garantiza resultados identicos entre operadores,
y no puede auditarse de forma sistematica. El laboratorio resuelve este problema
reescribiendo cada caso practico como un script que se ejecuta con un unico comando,
sin interaccion, produciendo la misma salida en cualquier entorno donde se ejecute.

La eleccion de la imagen base `nixos/nix` responde a los requisitos de reproducibilidad:
el gestor de paquetes Nix garantiza que cada herramienta instalada tiene una version
exacta determinada por un hash criptografico, eliminando la variabilidad entre builds
que afecta a gestores de paquetes convencionales como `apt`. Fish shell se utiliza para
los scripts de GPG por su sintaxis expresiva y su manejo explicito de errores mediante
condicionales; Bash se utiliza para los scripts de OpenSSL por su mayor compatibilidad
con el ecosistema de herramientas del sistema.

== Estructura del Repositorio

El repositorio esta organizado de forma que cada archivo tiene una responsabilidad unica
y delimitada. La raiz contiene los archivos de configuracion del entorno (Dockerfile,
compose.yml), el archivo de parametros de generacion de claves GPG (keyparams.conf)
y la documentacion (README.md). Los scripts de los casos practicos residen en el
directorio `scripts/`, nombrados con el prefijo `pc` seguido del numero del caso y una
descripcion del contenido.

```
crypto-lab/
├── Dockerfile              # Imagen NixOS con GPG, OpenSSL, Fish
├── compose.yml             # Servicio crypto-lab con volumen gnupg-data
├── README.md               # Instrucciones operativas
├── keyparams.conf          # Parametros batch para gpg --gen-key
└── scripts/
    ├── pc1-polybius-cipher.fish
    ├── pc2-symmetric-encryption.fish
    ├── pc3-key-generation.fish
    ├── pc4-revocation-certificate.fish
    ├── pc5-key-exchange.fish
    ├── pc6-digital-signature.fish
    ├── pc7-certificate-authority.sh
    ├── pc8-certificate-request.sh
    └── pc9-secure-email.md
```

El Dockerfile instala los paquetes necesarios como root (la imagen `nixos/nix` no
dispone de utilidades de gestion de usuarios), configura el directorio `~/.gnupg` con
permisos 700 y el parametro `allow-loopback-pinentry` en `gpg-agent.conf`. El
`compose.yml` define un volumen `gnupg-data` montado en `/root/.gnupg` para
persistir el anillo de claves entre sesiones, y monta el directorio del proyecto en
`/workspace` para permitir la edicion de scripts sin reconstruir la imagen.

== Descripcion de los Scripts

=== PC1: Cifrador de Polybios (`pc1-polybius-cipher.fish`)

Implementa el cifrador de sustitucion de Polybios en Fish shell. Define la tabla de 5x5
como un array de coordenadas y dos funciones: `encode_polybius`, que recorre cada
caracter de la entrada, localiza su posicion en el alfabeto y devuelve el par de digitos
correspondiente; y `decode_polybius`, que realiza la operacion inversa. El script
demuestra la codificacion y decodificacion de mensajes de ejemplo, incluyendo la nota
sobre el tratamiento compartido de I y J en la posicion 24.

=== PC2: Cifrado Simetrico (`pc2-symmetric-encryption.fish`)

Demuestra el ciclo completo de cifrado simetrico AES-256 con GnuPG. Crea un
documento de ejemplo, lo cifra en formato binario (`--symmetric --cipher-algo AES256`)
y en formato ASCII-armored (`--armor`), lo descifra y verifica la integridad comparando
el hash SHA-256 del archivo original con el del archivo descifrado. Todos los comandos
GPG usan `--batch --pinentry-mode loopback --passphrase` para eliminar cualquier
interaccion con el agente GPG o el dialogo de pinentry.

=== PC3: Generacion de Par de Claves (`pc3-key-generation.fish`)

Genera un par de claves RSA 4096 de forma completamente no interactiva usando el
archivo `keyparams.conf` con el parametro `--gen-key` en modo batch. El archivo de
parametros especifica el tipo de clave (RSA), la longitud (4096 bits), la caducidad
(1 ano), la identidad del titular y la frase de paso. El script exporta la clave publica
en formato ASCII-armored y muestra la huella digital del par generado.

=== PC4: Certificado de Revocacion (`pc4-revocation-certificate.fish`)

Genera un certificado de revocacion para la clave creada en PC3. Dado que Fish shell
no soporta heredocs (`<<`), las respuestas necesarias para `--gen-revoke` se alimentan
mediante `printf "y\n0\n...\ny\n" | gpg --command-fd 0`. El script incluye un
mecanismo de fallback mediante `python3 -c "subprocess.run(..., input=...)"` para
versiones de GPG que ignoran `--command-fd` en modo batch. Muestra los codigos de
razon de revocacion documentados en el libro de texto (0-3) e instrucciones para
publicar el certificado en un keyserver.

=== PC5: Intercambio de Claves (`pc5-key-exchange.fish`)

Simula el intercambio de claves publicas entre dos entidades (Alice y Bob) sobre la
clave de laboratorio. Exporta la clave publica en formato ASCII-armored, la importa al
anillo de claves, cifra un mensaje para el receptor usando su clave publica con
`--encrypt --recipient` y lo descifra con la clave privada correspondiente. Incluye el
manejo del modelo de confianza con `--trust-model always` para el entorno de
laboratorio, donde las claves no han sido verificadas fuera de banda.

=== PC6: Firma Digital (`pc6-digital-signature.fish`)

Demuestra las tres modalidades de firma digital con GPG: `--clearsign` (contenido
legible con firma adjunta, util para correo electronico), `--detach-sign --armor` (firma
en archivo separado, util para binarios y ejecutables) y `--sign --armor` (documento y
firma comprimidos en un unico archivo). Incluye una demostracion de deteccion de
manipulacion: copia el documento firmado, modifica una cadena con `sed` y ejecuta
`--verify`, confirmando que GPG detecta la alteracion y reporta una firma invalida.

=== PC7: Autoridad Certificadora (`pc7-certificate-authority.sh`)

Crea una CA raiz funcional equivalente a la del libro de texto (Windows Certificate
Services) pero implementada en OpenSSL sobre Linux. Inicializa la estructura de
directorios de la PKI (`certs/`, `private/`, `newcerts/`, `crl/`), genera el archivo
`openssl.cnf` con politicas de certificacion (`policy_strict` y `policy_loose`),
extensiones X.509 v3 (`v3_ca`, `usr_cert`, `server_cert`) y configuracion de CRL.
Genera la clave privada de la CA (RSA 4096 cifrada con AES-256), el certificado
autofirmado de la CA (valido 10 anos) y la CRL inicial. Muestra las huellas digitales
SHA-256 y SHA-1 del certificado para verificacion fuera de banda.

=== PC8: Solicitud y Revocacion de Certificados (`pc8-certificate-request.sh`)

Implementa el ciclo de vida completo de un certificado X.509. Genera la clave privada
del usuario (RSA 4096), crea el CSR con el subject alineado a la politica de la CA
(`C=ES, ST=Segovia, O=SiTour SA`), firma el CSR con la CA usando `policy_loose`
para permitir diferencias en los campos opcionales, verifica la cadena de confianza,
exporta el bundle en formato PKCS\#12 para importacion en clientes de correo,
revoca el certificado con razon `keyCompromise`, actualiza la CRL y verifica que el
certificado revocado falla la validacion con `-crl_check`. El script usa `set -euo pipefail`
y elimina `2>/dev/null` del paso de firma para que los errores sean visibles al operador.

=== PC9: Correo Electronico Cifrado (`pc9-secure-email.md`)

Documento Markdown que explica conceptualmente el estandar S/MIME para firma y
cifrado de correo electronico usando certificados X.509. Incluye diagramas de proceso
de firma y cifrado, la cadena de confianza PKI completa, comandos OpenSSL para
operaciones S/MIME desde linea de comandos (`smime -sign`, `smime -encrypt`,
`smime -verify`) y una tabla comparativa entre GPG/OpenPGP y S/MIME en terminos
de modelo de confianza, soporte en clientes de correo y uso corporativo.

== Decisiones de Diseño

La decision de usar Fish shell para los scripts de GPG (PC1-PC6) y Bash para los de
OpenSSL (PC7-PC8) responde a sus respectivas fortalezas: Fish ofrece una sintaxis
clara para operaciones interactivas simuladas y manejo de variables, mientras que Bash
es el estandar de facto para scripting de sistema y es la shell predeterminada en la
mayoria de los entornos de CI/CD y en el ecosistema OpenSSL.

El uso de `--pinentry-mode loopback` en todos los comandos GPG es fundamental para
la no interactividad: sin este parametro, GPG intenta abrir un dialogo grafico de
pinentry que falla en entornos sin TTY, como contenedores o pipelines CI/CD. La
directiva `allow-loopback-pinentry` en `gpg-agent.conf` habilita este comportamiento
a nivel de agente.

La persistencia del anillo de claves en un volumen Docker separado del contenedor
permite que el material criptografico generado en PC3 este disponible en PC4, PC5 y
PC6 sin necesidad de regenerarlo en cada sesion, lo que acelera el flujo de trabajo
del laboratorio y refleja la arquitectura de produccion donde los keystores persisten
independientemente del ciclo de vida de los contenedores.
