# PC9: Secure Email Using Digital Certificate (S/MIME)

## Conceptual Explanation

This practical case corresponds to the textbook's Caso Practico 9, which demonstrates
sending digitally signed and encrypted email using a digital certificate in Outlook Express.
The modern equivalent involves any S/MIME-capable mail client with a valid X.509 certificate.

---

## What Is S/MIME?

S/MIME (Secure/Multipurpose Internet Mail Extensions) is the standard protocol for
sending cryptographically signed and encrypted email using X.509 digital certificates.

It provides the four pillars of information security:

| Property        | Mechanism                                     |
| --------------- | --------------------------------------------- |
| Confidentiality | Message encrypted with recipient's public key |
| Integrity       | Hash digest included and verified             |
| Authenticity    | Signed with sender's private key              |
| Non-repudiation | Sender cannot deny having signed the message  |

---

## Prerequisites

1. A valid X.509 certificate issued by a trusted CA (from PC7 and PC8).
2. The certificate associated with your email account.
3. The recipient's public certificate (to encrypt messages to them).

---

## Process: Digitally Signing an Email

```

Sender's private key
|
v
[Document hash (SHA-256)] ----encrypt----> [Digital Signature]
|
Document content + Digital Signature -------+
|
v
[Signed Email sent]

```

1. The mail client computes a SHA-256 hash of the email content.
2. The hash is encrypted with the sender's **private key** (creating the signature).
3. The email is sent with the signature and the sender's **certificate** (public key) attached.
4. The recipient's client decrypts the signature using the sender's **public key**.
5. The decrypted hash is compared to a freshly computed hash of the received message.
6. If the hashes match: signature is **VALID** — content is authentic and unmodified.

---

## Process: Encrypting an Email

```
Recipient's public key
        |
        v
[Document content] ----encrypt----> [Encrypted message]
                                              |
                                              v
                                    [Sent to recipient]
                                              |
Recipient's private key                       |
        |                                     v
        +----------decrypt---------> [Original content]
```

1. The sender obtains the recipient's certificate (contains their public key).
2. The email body is encrypted using the recipient's **public key**.
3. Only the recipient can decrypt it using their **private key**.

---

## Configuration Steps (Modern Mail Clients)

### Thunderbird (current standard)

```bash
# Step 1: Import your PKCS#12 certificate bundle
# Tools > Account Settings > End-To-End Encryption > S/MIME > Manage Certificates
# Import: /workspace/pki/users/stella/stella.p12
# Password: UserCertPass2024!

# Step 2: Associate certificate with account
# Account Settings > End-To-End Encryption
# Select the imported certificate for signing
# Select the imported certificate for encryption

# Step 3: Obtain recipient's certificate
# The recipient must send you a signed email first
# Thunderbird will extract and store their certificate automatically
```

### Command-line S/MIME with OpenSSL

```bash
# Sign a message
openssl smime -sign \
    -in message.txt \
    -text \
    -signer /workspace/pki/users/stella/stella.crt \
    -inkey /workspace/pki/users/stella/stella.key \
    -passin pass:UserCertPass2024! \
    -certfile /workspace/pki/ca/certs/ca.crt \
    -out message_signed.eml

# Encrypt a message for the recipient
openssl smime -encrypt \
    -aes256 \
    -in message.txt \
    -out message_encrypted.eml \
    /workspace/pki/users/stella/stella.crt

# Decrypt a received message
openssl smime -decrypt \
    -in message_encrypted.eml \
    -inkey /workspace/pki/users/stella/stella.key \
    -passin pass:UserCertPass2024! \
    -out message_decrypted.txt

# Verify a signed message
openssl smime -verify \
    -in message_signed.eml \
    -CAfile /workspace/pki/ca/certs/ca.crt \
    -out message_content.txt
```

---

## Relationship Between Components (PKI Chain of Trust)

```
Root CA Certificate (SiTourCA)
        |
        | signs
        v
User Certificate (stella@sitour.com)
        |
        | contains public key
        v
Digital Signature on Email
        |
        | verified by recipient using
        v
Stella's Public Key (extracted from certificate)
```

The recipient trusts the email signature because:

1. The signature was created with Stella's private key.
2. Stella's certificate was issued and signed by SiTourCA.
3. The recipient trusts SiTourCA (the CA certificate is installed as trusted).

---

## Key Differences from GPG

| Aspect              | GPG (OpenPGP)                | S/MIME (X.509)                |
| ------------------- | ---------------------------- | ----------------------------- |
| Trust model         | Web of Trust (decentralized) | Hierarchical CA (centralized) |
| Certificate issuer  | Anyone can sign keys         | Trusted CA must sign          |
| Corporate use       | Less common                  | Standard in enterprises       |
| Mail client support | Requires plugin              | Built into most clients       |
| Revocation          | Keyserver CRL                | OCSP / CRL distribution       |

---

## SRE Operational Notes

- Automate certificate renewal before expiry to avoid service disruption.
- Monitor certificate expiry dates: `openssl x509 -in cert.crt -noout -enddate`
- Store private keys in encrypted vaults (HashiCorp Vault, AWS Secrets Manager).
- Distribute CA certificates through configuration management (Ansible, Puppet, Chef).
- For internal email encryption at scale, consider an automated S/MIME gateway.
