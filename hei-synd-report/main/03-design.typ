#import "@preview/hei-synd-report:0.1.1": *
#import "../metadata.typ": *
#pagebreak()

= Marco Teorico

== Privacidad de la Informacion

Desde que el ser humano es capaz de comunicarse por escrito, ha existido la necesidad
de preservar la confidencialidad de los mensajes. La criptografia ---del griego *kryptos*
(oculto) y *graphia* (escritura)--- es la ciencia que estudia los metodos para transformar
informacion legible en una forma ininteligible para todo receptor no autorizado.

Los primeros metodos documentados datan del siglo V a.C. La *escitala* espartana
utilizaba transposicion: se enrollaba una tira de cuero sobre un baston de diametro fijo
y se escribia el mensaje en sentido longitudinal; al desenrollarla, los caracteres quedaban
desordenados. Solo quien poseyera un baston del mismo diametro podia descifrar el
mensaje. A mediados del siglo II a.C., el historiador griego Polybios desarrollo el primer
cifrador de sustitucion documentado: cada letra se reemplazaba por su par de
coordenadas en una tabla de 5x5. En el siglo I a.C., Julio Cesar utilizó el desplazamiento
fijo de tres posiciones en el alfabeto. En el siglo XVI, Blaise de Vigenere perfecciono
este concepto con un cifrador polialfabetico de 26 alfabetos que eliminaba la
vulnerabilidad del analisis de frecuencias.

En el contexto de infraestructuras digitales modernas, la privacidad de la informacion
se articula en torno a cuatro propiedades fundamentales: *confidencialidad* (solo el
destinatario legitimo puede leer el mensaje), *integridad* (el mensaje no ha sido
alterado en transito), *autenticidad* (el remitente es quien dice ser) y *no repudio*
(el remitente no puede negar haber enviado el mensaje).

== Criptografia Simetrica

La criptografia simetrica ---tambien llamada de clave privada--- utiliza la misma clave
tanto para cifrar como para descifrar. Todos los metodos criptograficos clasicos son
simetricos: el cifrador de Cesar, el de Vigenere y la escitala requieren que emisor y
receptor compartan previamente el secreto (la clave).

Los algoritmos simetricos modernos incluyen DES (Data Encryption Standard, 56 bits,
hoy considerado inseguro), 3DES (triple aplicacion de DES), RC4 (algoritmo de flujo),
IDEA y AES (Advanced Encryption Standard, 128/256 bits, estandar actual). Se
clasifican en dos categorias:

- *Algoritmos de bloque*: dividen el mensaje en bloques de bits de igual tamano y
  cifran cada bloque de forma independiente. AES opera sobre bloques de 128 bits.
- *Algoritmos de flujo*: cifran bit a bit o byte a byte segun se genera la informacion.
  El algoritmo A5, usado en telefonia movil GSM, es de este tipo.

El *principio de Kerckhoff* establece que la fortaleza de un sistema de cifrado debe
residir en la clave y no en el algoritmo. La mayoria de los algoritmos modernos son
de dominio publico; su seguridad se basa exclusivamente en el secreto de la clave.

La limitacion fundamental de la criptografia simetrica es el problema de distribucion de
claves. Para que $n$ entidades puedan comunicarse de forma segura entre si, se necesitan
$n(n-1)/2$ claves distintas. Para 100 usuarios esto representa 4950 secretos compartidos,
lo que hace el sistema inmanejable a escala, y plantea ademas el problema de como
intercambiar la clave de forma segura por un canal potencialmente inseguro.

== Criptografia Asimetrica

En 1976, Whitfield Diffie y Martin Hellman publicaron el concepto de criptografia de
clave publica, que resuelve de forma elegante el problema de distribucion de claves.
Cada entidad posee un par de claves matematicamente relacionadas mediante funciones
de un solo sentido: una *clave publica*, que puede difundirse libremente, y una
*clave privada*, que jamas debe revelarse.

El mecanismo de cifrado asimetrico funciona del siguiente modo: para enviar un mensaje
confidencial al receptor B, el emisor A cifra el mensaje con la *clave publica de B*.
Solo B puede descifrarlo porque es el unico que posee la *clave privada de B*. Aunque
un atacante intercepte el mensaje cifrado y conozca la clave publica de B, no puede
descifrar el mensaje sin la clave privada correspondiente.

Las claves se generan a partir de operaciones matematicas computacionalmente
irreversibles. El algoritmo RSA se basa en la dificultad de factorizar el producto de dos
numeros primos grandes: la clave publica contiene el producto $n = p * q$; la clave
privada contiene uno de los factores. Los algoritmos ElGamal y Diffie-Hellman se basan
en el problema del logaritmo discreto.

La *criptografia hibrida* combina lo mejor de ambos paradigmas: la clave simetrica de
sesion se negocia de forma segura usando criptografia asimetrica; el cifrado de los datos
se realiza con la clave simetrica, mucho mas rapido. TLS opera exactamente de esta
manera: el handshake usa RSA o ECDH para acordar la clave de sesion, y AES para
cifrar el trafico posterior.

== Funciones Hash

Las funciones hash (o funciones resumen) son funciones criptograficas de un solo
sentido que transforman una entrada de tamano arbitrario en una salida de longitud fija
denominada *digest* o *resumen*. Sus propiedades fundamentales son:

- *Determinismo*: la misma entrada siempre produce el mismo hash.
- *Resistencia a colisiones*: es computacionalmente inviable encontrar dos entradas
  distintas que produzcan el mismo hash.
- *Irreversibilidad*: es computacionalmente inviable reconstruir la entrada original a
  partir del hash.
- *Efecto avalancha*: un cambio minimo en la entrada (un solo bit) produce un hash
  completamente diferente.

Los algoritmos mas utilizados son MD5 (128 bits, hoy inseguro para propositos
criptograficos), SHA-1 (160 bits, tambien comprometido), SHA-256 y SHA-512 (familia
SHA-2, estandar actual) y SHA-3 (basado en la construccion Keccak). Los sistemas
Linux almacenan las contrasenas de usuario como hashes SHA-512 en `/etc/shadow`.

== Firma Digital

La firma digital es el mecanismo criptografico que proporciona autenticidad, integridad
y no repudio en documentos electronicos. Su proceso combina funciones hash con
criptografia asimetrica:

+ Se calcula el hash del documento usando un algoritmo como SHA-256.
+ El hash se cifra con la *clave privada* del firmante. El resultado es la firma digital.
+ La firma digital se adjunta al documento o se almacena por separado.

La verificacion invierte el proceso: se descifra la firma con la *clave publica* del firmante,
obteniendo el hash original; se calcula independientemente el hash del documento
recibido; si ambos hashes coinciden, la firma es valida. Esto garantiza que el documento
no ha sido alterado (integridad) y que fue firmado por quien posee la clave privada
correspondiente (autenticidad y no repudio).

Una propiedad clave diferencia la firma digital de la manuscrita: dos documentos distintos
firmados por la misma persona produciran firmas digitales distintas, ya que el hash de
cada documento es unico.

== Certificado Digital

Un certificado digital (estandar X.509) es un documento electronico que vincula una
identidad ---nombre, organizacion, direccion de correo--- con una clave publica, mediante
la firma criptografica de una *Autoridad Certificadora* (CA) de confianza.

Los campos principales de un certificado X.509 son: version y numero de serie,
algoritmo de firma, emisor (CA), periodo de validez, titular (*subject*), clave publica del
titular, uso permitido de la clave, extension de uso extendido y firma digital de la CA.
El formato mas extendido en Internet es X.509 v3.

La confianza en un certificado es transitiva: el cliente confia en la CA raiz (cuyo
certificado esta preinstalado en el sistema operativo o navegador), la CA raiz ha firmado
el certificado del servidor, por lo tanto el cliente puede confiar en el servidor. Esta
estructura jerarquica es la base de la *cadena de confianza*.

== Infraestructura de Clave Publica (PKI)

La PKI (*Public Key Infrastructure*) es el conjunto de hardware, software, politicas y
procedimientos necesarios para gestionar el ciclo de vida de certificados digitales y
claves publicas. Permite alcanzar los cuatro objetivos de la seguridad informatica:
autenticidad, confidencialidad, integridad y no repudio.

Sus componentes principales son:

- *Autoridad Certificadora (CA)*: entidad de confianza que emite, firma y revoca
  certificados digitales. Es el nucleo de la PKI.
- *Autoridad de Registro (RA)*: verifica la identidad de los solicitantes antes de que
  la CA emita el certificado. En organizaciones pequeñas, la CA y la RA pueden ser
  la misma entidad.
- *Repositorio de certificados*: almacena los certificados emitidos y las Listas de
  Revocacion de Certificados (CRL).
- *Lista de Revocacion de Certificados (CRL)*: lista firmada por la CA que registra los
  certificados que han sido invalidados antes de su fecha de caducidad, por compromiso
  de la clave privada, cambio de identidad del titular u otras razones.
- *OCSP (Online Certificate Status Protocol)*: alternativa moderna a las CRL que
  permite consultar el estado de revocacion de un certificado en tiempo real.

En Espana, la Fabrica Nacional de Moneda y Timbre (FNMT) actua como CA raiz
para los certificados de ciudadanos utilizados en tramites con la Administracion Publica.
