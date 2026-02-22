# pc9-secure-email.md

## Caso Práctico 9: Cifrado de Correo Electrónico con Certificado Digital

### Objetivo

Explicar conceptualmente el proceso de envío de correo electrónico firmado y cifrado
mediante un certificado digital X.509, equivalente al Caso Práctico 9 del libro de texto
(Outlook Express), pero aplicado a entornos modernos y compatibles con SRE.

---

### Contexto Teórico

Cuando un usuario envía un correo electrónico firmado digitalmente mediante un
certificado X.509, se garantizan las siguientes propiedades de seguridad:

| Propiedad            | Mecanismo                                                          |
| -------------------- | ------------------------------------------------------------------ |
| **Autenticidad**     | La firma digital prueba que el remitente es quien dice ser         |
| **Integridad**       | Cualquier modificación del mensaje invalida la firma               |
| **No repudio**       | El remitente no puede negar haber enviado el mensaje               |
| **Confidencialidad** | El cifrado con clave pública del destinatario protege el contenido |

---

### Proceso Técnico Detallado

#### Paso 1: Asociar el Certificado a la Cuenta de Correo

El cliente de correo (Thunderbird, Outlook, etc.) debe conocer qué certificado
usar para firmar mensajes salientes. El certificado X.509 debe contener la misma
dirección de correo electrónico que la cuenta configurada.

```
Cuenta: macarena@sitour.com
Certificado subject: CN=Macarena Subtil, emailAddress=macarena@sitour.com
Emitido por: SiTourCA
Válido: 22/09/2009 - 22/09/2010
```

#### Paso 2: Firma del Mensaje Saliente

Al enviar un mensaje con firma digital activada:

```
1. El cliente calcula el hash SHA-256 del contenido del mensaje.
2. El hash se cifra con la CLAVE PRIVADA del remitente.
3. El resultado cifrado = firma digital.
4. La firma digital + el certificado público del remitente
   se adjuntan al mensaje (MIME type: multipart/signed).
```

Formato del mensaje firmado (S/MIME):

```
Content-Type: multipart/signed; protocol="application/pkcs7-signature"

--boundary
Content-Type: text/plain

La compra de los 10000 billetes de avión encargados por el director...

--boundary
Content-Type: application/pkcs7-signature
[firma digital en base64]
--boundary--
```

#### Paso 3: Verificación por el Destinatario

Al recibir el mensaje:

```
1. El cliente extrae el certificado del remitente adjunto al mensaje.
2. Verifica que el certificado fue emitido por una CA de confianza.
3. Descifra la firma con la CLAVE PÚBLICA del remitente.
4. Calcula el hash SHA-256 del cuerpo del mensaje recibido.
5. Compara ambos hashes: si coinciden, la firma es VÁLIDA.
```

#### Paso 4: Cifrado del Mensaje (Confidencialidad)

Para enviar un mensaje cifrado al destinatario, el remitente necesita
la **clave pública** del destinatario (obtenida de su certificado):

```
1. Remitente obtiene el certificado del destinatario (de correo previo firmado).
2. Genera una clave de sesión simétrica aleatoria (AES-256).
3. Cifra el cuerpo del mensaje con la clave de sesión.
4. Cifra la clave de sesión con la clave pública del destinatario.
5. Envía: cuerpo cifrado + clave de sesión cifrada.

Destinatario:
1. Descifra la clave de sesión con su CLAVE PRIVADA.
2. Descifra el cuerpo con la clave de sesión recuperada.
```

---

### Configuración en Clientes de Correo Modernos

#### Mozilla Thunderbird (Recomendado en Entornos SRE)

```
1. Herramientas > Configuración de cuenta > [cuenta] > Seguridad
2. Certificado de firma digital: [Seleccionar] -> elegir certificado personal
3. Cifrado: [Seleccionar] -> mismo certificado (para S/MIME)
4. Al redactar: Seguridad > Firmar digitalmente
                           Cifrar este mensaje
```

#### Configuración via CLI con msmtp + gpg (Automatización SRE)

```bash
# Firmar y cifrar con GPG (OpenPGP, alternativa a S/MIME)
echo "Mensaje confidencial" | \
  gpg --batch --yes \
      --pinentry-mode loopback \
      --passphrase "${PASSPHRASE}" \
      --encrypt \
      --sign \
      --armor \
      --recipient "fernando@sitour.com" \
  | msmtp --from=macarena@sitour.com fernando@sitour.com
```

---

### Diferencias: S/MIME vs OpenPGP

| Característica      | S/MIME (X.509)                  | OpenPGP (GPG)                    |
| ------------------- | ------------------------------- | -------------------------------- |
| **Infraestructura** | Requiere CA (PKI jerárquica)    | Red de confianza (web of trust)  |
| **Certificados**    | Emitidos por CA (costo posible) | Pares de claves auto-generados   |
| **Compatibilidad**  | Nativa en Outlook, Apple Mail   | Requiere plugin (Enigmail, etc.) |
| **Uso corporativo** | Estándar en empresas            | Común en código abierto/SRE      |
| **Revocación**      | CRL / OCSP                      | Keyservers / certificados revoc. |

---

### Automatización SRE: Pipeline de Notificaciones Cifradas

En entornos SRE, el cifrado de correo puede integrarse en pipelines de alertas:

```bash
#!/usr/bin/env bash
# Enviar alerta de seguridad cifrada al equipo

ALERT_MSG="CRITICAL: Certificate expiry in 30 days for api.sitour.com"
SECURITY_TEAM="security@sitour.com"
GPG_RECIPIENT_FINGERPRINT="ABCD1234EFGH5678"

echo "${ALERT_MSG}" | \
  gpg --batch --yes \
      --pinentry-mode loopback \
      --encrypt \
      --armor \
      --recipient "${GPG_RECIPIENT_FINGERPRINT}" \
  | sendmail "${SECURITY_TEAM}"
```

---

### Flujo de Confianza en el Ejemplo del Libro

```
[SiTourCA]  <-- Autoridad Certificadora Raíz
     |
     +-- Firma el certificado de Macarena
     +-- Firma el certificado de Fernando

[Macarena] <----firma----> [Fernando]
  - Tiene cert propio                - Tiene cert propio
  - Tiene cert de Fernando           - Tiene cert de Macarena
  - Puede cifrar para Fernando       - Puede cifrar para Macarena
  - Puede verificar firma Fernando   - Puede verificar firma Macarena
```

Ambos confían en SiTourCA como raíz, por lo que automáticamente confían
en cualquier certificado emitido por esa CA.

---

### Referencia a Caso Práctico 8

El certificado utilizado en este caso práctico fue obtenido mediante el proceso
descrito en el Caso Práctico 8:

- URL del servidor de certificados: `http://jupiter/certsrv`
- Tipo de certificado: Protección de correo electrónico
- CA emisora: SiTourCA
- Válido desde: 22/09/2009 hasta 22/09/2010

La única forma que tiene el destinatario de verificar la firma es mediante
el certificado digital del remitente, el cual se envía adjunto con el correo.
Al tenerlo, podrá usar la clave pública para enviar correo cifrado, garantizando
no repudio, confidencialidad e integridad.

---

_Caso Práctico 9 - Guía de Automatización Criptográfica con Enfoque SRE_
