#import "@preview/hei-synd-report:0.1.1": *
#import "../metadata.typ": *
#pagebreak()

= Conclusiones

El desarrollo de este laboratorio de automatizacion criptografica ha permitido alcanzar
los objetivos propuestos y extraer conclusiones tecnicas relevantes tanto en el plano
criptografico como en el operativo.

== En relacion con los objetivos especificos

Los fundamentos teoricos de la criptografia simetrica, asimetrica y las funciones hash
quedaron anclados en implementaciones concretas y ejecutables. La diferencia entre
cifrar con clave simetrica compartida (PC2) y cifrar con clave publica del receptor (PC5)
deja de ser una abstraccion teorica cuando ambos procesos pueden ejecutarse, compararse
y verificarse en el mismo entorno, con salidas reproducibles. El principio de Kerckhoff
---la seguridad reside en la clave, no en el algoritmo--- se hace tangible al constatar
que los algoritmos usados (AES-256, RSA 4096, SHA-256) son de dominio publico y su
fortaleza depende exclusivamente del secreto y la correcta gestion de las claves.

La automatizacion de la generacion de claves RSA 4096 mediante `keyparams.conf` y
el modo `--batch` de GnuPG demuestra que es posible codificar politicas criptograficas
---longitud minima de clave, algoritmo, caducidad--- en artefactos versionables y
auditables, eliminando la variabilidad que introduce la interaccion humana. El mismo
principio aplica a la generacion del certificado de revocacion inmediatamente despues
del par de claves: una buena practica de seguridad que los procesos manuales omiten
con frecuencia puede convertirse en un paso obligatorio e ineludible del script.

La implementacion de la firma digital en sus tres modalidades (PC6) clarifica la distincion
operativa entre ellas: `--clearsign` para documentos que humanos deben poder leer
sin software criptografico, `--detach-sign` para artefactos binarios cuya integridad
debe verificarse en pipelines de despliegue, y `--sign` para archivos que se almacenan
como unidad autocontenida. La demostracion de deteccion de manipulacion confirma
empiricamente la propiedad de integridad de la firma digital.

La instalacion de la Autoridad Certificadora con OpenSSL (PC7-PC8) traduce el
concepto abstracto de PKI en una estructura operativa concreta con sus archivos de
configuracion, base de datos de certificados emitidos, CRL y politicas de certificacion.
El ciclo de vida completo ---generacion de clave, CSR, firma por la CA, verificacion,
exportacion PKCS\#12, revocacion y actualizacion de CRL--- queda documentado en
un script reproducible que puede adaptarse a cualquier PKI interna.

La reproducibilidad del entorno mediante Docker y Nix ha demostrado ser una
decision tecnica solida: la misma imagen construida en sistemas operativos distintos
produce resultados identicos, y el volumen Docker separa correctamente el material
criptografico del ciclo de vida efimero del contenedor.

== Lecciones tecnicas y limitaciones

La principal limitacion encontrada durante el desarrollo fue la incompatibilidad de la
imagen `nixos/nix` con las utilidades convencionales de gestion de usuarios (`useradd`,
`adduser`), que obligo a ejecutar el laboratorio como root. En un entorno de produccion,
esta limitacion se resolveria construyendo sobre una imagen base que incluya estas
herramientas, o bien mediante una imagen NixOS derivada con un entorno de usuario
configurado declarativamente en un archivo `.nix`.

La incompatibilidad de Fish shell con heredocs (`<< 'EOF'`) requirio implementar
el suministro de respuestas a `gpg --gen-revoke` mediante `printf` y `--command-fd 0`,
con un fallback en Python. Esto ilustra un principio SRE importante: las herramientas
de automatizacion deben diseñarse con mecanismos de fallback explicitos ante
comportamientos variables entre versiones del software subyacente.

== Perspectiva SRE y trabajo futuro

El laboratorio establece una base solida sobre la que construir practicas SRE avanzadas
en gestion criptografica. Las mejoras mas significativas para un entorno de produccion
incluirian la integracion con HashiCorp Vault para la gestion centralizada de secretos
y frases de paso, la automatizacion de la rotacion de certificados TLS con cert-manager
en Kubernetes, la firma de imagenes Docker con Cosign en el pipeline CI/CD, y la
implementacion de una CA intermedia para separar la CA raiz (offline) de la CA
operativa (online).

En terminos de cadena de suministro de software, la combinacion de Nix (builds
reproducibles con hashes criptograficos) y firma de artefactos (Cosign, in-toto)
ofrece una arquitectura de alta integridad que puede auditarse extremo a extremo:
desde el codigo fuente hasta la imagen en produccion, cada transformacion esta
firmada y verificable. Este es el horizonte hacia el que apuntan las practicas SRE
de seguridad mas maduras, y el laboratorio proporciona los fundamentos necesarios
para comprenderlas e implementarlas.
