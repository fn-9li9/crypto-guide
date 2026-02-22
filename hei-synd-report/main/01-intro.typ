#import "@preview/hei-synd-report:0.1.1": *
#import "../metadata.typ": *
#pagebreak()

= Introduccion

La criptografia es una disciplina cuya historia abarca mas de veinticinco siglos, desde la
escitala espartana del siglo V a.C. hasta los algoritmos RSA y AES que protegen hoy
las comunicaciones globales. Lo que comenzó como un metodo para ocultar ordenes
militares se ha convertido en el fundamento tecnico sobre el que descansa la confianza
digital: transacciones bancarias, comunicaciones corporativas, autenticacion de identidades
y la integridad de la cadena de suministro de software dependen directamente de
primitivas criptograficas correctamente implementadas.

En el contexto de la Ingenieria de Fiabilidad de Sitios (*Site Reliability Engineering*, SRE),
la criptografia deja de ser una responsabilidad exclusiva del area de seguridad para
convertirse en un componente operativo transversal. La caducidad no detectada de un
certificado TLS, la rotacion manual y propensa a errores de claves de cifrado, o la
ausencia de un certificado de revocacion preparado son causas documentadas de
incidentes de disponibilidad con consecuencias legales y reputacionales. La automatizacion
y la reproducibilidad de las operaciones criptograficas son, por tanto, requisitos de
fiabilidad, no optimizaciones opcionales.

El presente informe documenta el desarrollo de un laboratorio de automatizacion
criptografica reproducible, construido sobre una imagen Docker basada en `nixos/nix`.
El laboratorio implementa nueve casos practicos extraidos de la Unidad 4 del libro de
texto *Seguridad Informatica* (paginas 81-106), trasladando los ejercicios originales
---concebidos para entornos interactivos con interfaces graficas--- a scripts completamente
no interactivos, versionables y ejecutables en pipelines de integracion continua.

Los casos practicos cubren el espectro completo de los sistemas de identificacion
criptografica: desde cifrados historicos de sustitucion (Polybios) hasta la instalacion
de una Autoridad Certificadora con OpenSSL, pasando por cifrado simetrico y asimetrico
con GnuPG, firma digital de documentos y gestion del ciclo de vida de certificados X.509.

El laboratorio se estructura como un repositorio Git con la siguiente logica: cada caso
practico es un script autonomo que puede ejecutarse de forma independiente o secuencial,
el entorno es completamente efimero y reproducible mediante `docker compose build` y
`docker compose run`, y todo el material criptografico generado persiste en un volumen
Docker gestionado, separado del contenedor.

Este informe esta organizado en las siguientes secciones: objetivos del laboratorio,
justificacion tecnica de las decisiones de diseño, marco teorico de los conceptos
criptograficos abordados, descripcion de la implementacion (estructura de archivos y
logica de cada script), resultados de la ejecucion de cada caso practico, y conclusiones
en relacion con los objetivos propuestos.
