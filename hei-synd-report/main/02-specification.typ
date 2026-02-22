#import "@preview/hei-synd-report:0.1.1": *
#import "../metadata.typ": *
#pagebreak()

= Objetivos y Justificacion

== Objetivo General

Desarrollar las competencias tecnicas necesarias para implementar, automatizar y operar
sistemas criptograficos y de identificacion digital en entornos de infraestructura
reproducible, aplicando principios de ingenieria de fiabilidad de sitios (SRE) para
minimizar el riesgo operativo derivado de procesos criptograficos manuales o no
reproducibles.

== Objetivos Especificos

+ Comprender y aplicar los fundamentos teoricos de la criptografia simetrica, asimetrica
  y las funciones hash en el contexto de la seguridad de infraestructuras.

+ Implementar y automatizar la generacion de pares de claves asimetricas RSA 4096
  mediante GnuPG en modo no interactivo, usando archivos de parametros y el modo
  batch.

+ Demostrar el proceso completo de cifrado y descifrado simetrico con GnuPG (AES-256),
  verificando la integridad mediante funciones hash SHA-256.

+ Generar, exportar, importar y gestionar certificados de revocacion de forma
  automatizada, aplicando mejores practicas del ciclo de vida de claves.

+ Implementar la firma digital de documentos mediante multiples modalidades (`--clearsign`,
  `--detach-sign`, `--sign`) y verificar la validez de firmas, incluyendo la deteccion
  automatica de manipulaciones.

+ Instalar y configurar una Autoridad Certificadora (CA) raiz utilizando OpenSSL,
  emitiendo certificados de usuario con cadena de confianza verificable.

+ Gestionar el ciclo de vida completo de un certificado X.509: solicitud (CSR), emision,
  verificacion, exportacion PKCS\#12 y revocacion con actualizacion de CRL.

+ Comprender el modelo conceptual del cifrado de correo electronico mediante
  certificados digitales (S/MIME), incluyendo firma y cifrado de mensajes.

+ Garantizar la reproducibilidad total del entorno de laboratorio mediante Docker y
  Docker Compose, de modo que cualquier operador pueda replicar exactamente el
  mismo entorno sin dependencias del sistema anfitrion.

+ Aplicar principios SRE al diseño del laboratorio: no interactividad, idempotencia,
  trazabilidad mediante salidas estandar y gestion del error con codigos de salida
  explicitos.

== Justificacion

=== Por que la automatizacion es critica en operaciones criptograficas

Los procesos criptograficos manuales son inherentemente propensos al error humano.
La generacion de claves con parametros incorrectos, la omision del certificado de
revocacion inmediatamente despues de crear el par de claves, o el olvido de renovar
un certificado TLS antes de su caducidad son causas reales y frecuentes de incidentes
de seguridad con impacto en la disponibilidad del servicio.

La automatizacion elimina esta clase de errores al codificar los parametros correctos
en scripts versionados, revisados y auditables. En SRE, la automatizacion es ademas
un principio fundamental de reduccion de *toil*: el trabajo manual, repetitivo y sin valor
duradero. Gestionar certificados de forma manual en una infraestructura de cientos o
miles de servicios no es escalable; es necesario automatizar la emision, renovacion,
distribucion y revocacion como parte del ciclo normal de operaciones.

=== Por que la reproducibilidad es obligatoria en SRE

Un entorno reproducible es aquel que puede recrearse exactamente a partir de su
definicion ---codigo, configuracion, dependencias--- independientemente de quien lo
ejecute y cuando. En SRE, la reproducibilidad es un requisito de fiabilidad: si el entorno
de laboratorio, pre-produccion y produccion difieren, las pruebas y validaciones
realizadas en el laboratorio pierden validez operativa.

La imagen `nixos/nix` refuerza esta garantia: el gestor de paquetes Nix instala cada
herramienta con una version exacta y determinista, identificada por un hash criptografico
en el store de Nix. Combinado con Docker, cualquier operador obtiene exactamente el
mismo entorno independientemente de su sistema operativo anfitrion.

=== Riesgos de los procesos criptograficos manuales

Los principales riesgos operativos de los procesos manuales son los siguientes:

- *Parametros debiles*: generacion de claves con longitud insuficiente o algoritmos
  obsoletos (MD5, SHA-1, DES) por error o desconocimiento.
- *Reutilizacion de claves* entre entornos de desarrollo y produccion.
- *Almacenamiento inseguro* de claves privadas en texto plano o en repositorios de
  codigo versionado.
- *Caducidad no detectada* de certificados, que provoca interrupciones del servicio
  difíciles de diagnosticar rapidamente.
- *Ausencia de certificados de revocacion* preparados de antemano, que impide
  responder con agilidad ante el compromiso de una clave privada.
- *Dependencia del conocimiento individual*: procesos no documentados que solo
  pueden ejecutar una o dos personas del equipo.

=== Importancia de la gestion del ciclo de vida de claves

La gestion del ciclo de vida (*Key Lifecycle Management*) comprende generacion,
distribucion, almacenamiento, uso, rotacion, revocacion y destruccion segura de claves.
En una infraestructura moderna, cada una de estas etapas debe estar automatizada y
auditada. La rotacion periodica acota la ventana de exposicion ante un compromiso:
si una clave se filtra sin que sea detectada, la rotacion limita el periodo durante el cual
el atacante puede usarla. Automatizar la rotacion sin impacto en la disponibilidad del
servicio (*zero-downtime rotation*) es una de las tareas mas exigentes y valoradas en
los equipos de SRE orientados a seguridad.
