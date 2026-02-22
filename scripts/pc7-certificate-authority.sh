#!/bin/bash
# pc7-certificate-authority.sh
# Practical Case 7: Installation of a Certificate Authority (CA) using OpenSSL
# Creates a self-signed root CA equivalent to the textbook's Windows CA scenario
# but implemented on Linux using OpenSSL for full automation and reproducibility

set -euo pipefail

CA_DIR="/workspace/pki/ca"
CA_KEY="$CA_DIR/private/ca.key"
CA_CERT="$CA_DIR/certs/ca.crt"
CA_DB="$CA_DIR/index.txt"
CA_SERIAL="$CA_DIR/serial"
CA_PASSPHRASE="CaRootPassphrase2024!"
CA_SUBJECT="/C=ES/ST=Segovia/L=Fuentemilanos/O=SiTour SA/OU=Division de certificados/CN=SiTourCA/emailAddress=ca@sitour.com"

# --- Directory and database initialization ---
initialize_ca_structure() {
    echo "--- Initializing CA directory structure ---"

    mkdir -p "$CA_DIR"/{certs,private,newcerts,crl}
    chmod 700 "$CA_DIR/private"

    # Initialize certificate database
    touch "$CA_DB"
    echo "01" > "$CA_SERIAL"
    echo "01" > "$CA_DIR/crlnumber"

    # Create minimal OpenSSL configuration
    cat > "$CA_DIR/openssl.cnf" << 'OPENSSLCONF'
[ ca ]
default_ca = CA_default

[ CA_default ]
dir               = /workspace/pki/ca
certs             = $dir/certs
crl_dir           = $dir/crl
new_certs_dir     = $dir/newcerts
database          = $dir/index.txt
serial            = $dir/serial
RANDFILE          = $dir/private/.rand
private_key       = $dir/private/ca.key
certificate       = $dir/certs/ca.crt
crlnumber         = $dir/crlnumber
crl               = $dir/crl/ca.crl
crl_extensions    = crl_ext
default_crl_days  = 30
default_md        = sha256
name_opt          = ca_default
cert_opt          = ca_default
default_days      = 365
preserve          = no
policy            = policy_strict
copy_extensions   = copy

[ policy_strict ]
countryName             = match
stateOrProvinceName     = match
organizationName        = match
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ policy_loose ]
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ req ]
default_bits        = 4096
distinguished_name  = req_distinguished_name
string_mask         = utf8only
default_md          = sha256
x509_extensions     = v3_ca

[ req_distinguished_name ]
countryName                     = Country Name (2 letter code)
stateOrProvinceName             = State or Province Name
localityName                    = Locality Name
0.organizationName              = Organization Name
organizationalUnitName          = Organizational Unit Name
commonName                      = Common Name
emailAddress                    = Email Address

[ v3_ca ]
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints       = critical, CA:true
keyUsage               = critical, digitalSignature, cRLSign, keyCertSign

[ v3_intermediate_ca ]
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints       = critical, CA:true, pathlen:0
keyUsage               = critical, digitalSignature, cRLSign, keyCertSign

[ usr_cert ]
basicConstraints       = CA:FALSE
nsCertType             = client, email
nsComment              = "OpenSSL Generated Client Certificate"
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid,issuer
keyUsage               = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage       = clientAuth, emailProtection

[ server_cert ]
basicConstraints       = CA:FALSE
nsCertType             = server
nsComment              = "OpenSSL Generated Server Certificate"
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid,issuer
keyUsage               = critical, digitalSignature, keyEncipherment
extendedKeyUsage       = serverAuth

[ crl_ext ]
authorityKeyIdentifier = keyid:always

[ ocsp ]
basicConstraints       = CA:FALSE
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid,issuer
keyUsage               = critical, digitalSignature
extendedKeyUsage       = critical, OCSPSigning
OPENSSLCONF

    echo "CA directory structure initialized at: $CA_DIR"
}

generate_ca_key() {
    echo ""
    echo "--- Generating CA Root Private Key (RSA 4096) ---"
    echo "The CA private key is the most sensitive key in the PKI."
    echo "In production: store offline in HSM or encrypted cold storage."
    echo ""

    # Generate encrypted CA private key
    openssl genrsa \
        -aes256 \
        -passout "pass:$CA_PASSPHRASE" \
        -out "$CA_KEY" \
        4096

    chmod 400 "$CA_KEY"
    echo "CA private key generated: $CA_KEY"
    echo "Key permissions set to 400 (read-only by owner)."
}

generate_ca_certificate() {
    echo ""
    echo "--- Generating Self-Signed Root CA Certificate ---"
    echo "Validity: 10 years (CA certificates have long validity periods)"
    echo ""

    # Generate self-signed root certificate
    openssl req \
        -new \
        -x509 \
        -days 3650 \
        -sha256 \
        -extensions v3_ca \
        -key "$CA_KEY" \
        -passin "pass:$CA_PASSPHRASE" \
        -subj "$CA_SUBJECT" \
        -config "$CA_DIR/openssl.cnf" \
        -out "$CA_CERT"

    echo "Root CA certificate generated: $CA_CERT"
    echo ""
    echo "Certificate details:"
    openssl x509 -in "$CA_CERT" -noout -text | grep -E "(Subject:|Issuer:|Not Before|Not After|Public Key Algorithm|RSA Public-Key)"
}

display_ca_certificate() {
    echo ""
    echo "--- Full CA Certificate Information ---"
    openssl x509 -in "$CA_CERT" -noout -text | head -40
    echo "..."
    echo ""
    echo "Certificate fingerprints:"
    openssl x509 -in "$CA_CERT" -noout -fingerprint -sha256
    openssl x509 -in "$CA_CERT" -noout -fingerprint -sha1
}

generate_initial_crl() {
    echo ""
    echo "--- Generating Initial Certificate Revocation List (CRL) ---"

    openssl ca \
        -config "$CA_DIR/openssl.cnf" \
        -gencrl \
        -passin "pass:$CA_PASSPHRASE" \
        -out "$CA_DIR/crl/ca.crl" 2>/dev/null

    echo "Initial CRL created: $CA_DIR/crl/ca.crl"
    echo "CRL details:"
    openssl crl -in "$CA_DIR/crl/ca.crl" -noout -text | head -15
}

show_pki_summary() {
    echo ""
    echo "=== PKI INSTALLATION SUMMARY ==="
    echo ""
    echo "Certificate Authority: SiTourCA"
    echo "CA Certificate: $CA_CERT"
    echo "CA Private Key: $CA_KEY (protected)"
    echo "Database:       $CA_DB"
    echo "CRL:            $CA_DIR/crl/ca.crl"
    echo ""
    echo "PKI Components installed:"
    echo "  [CA]  Certificate Authority (SiTourCA) - root of trust"
    echo "  [RA]  Registration Authority - handled by CA in this lab"
    echo "  [CRL] Certificate Revocation List - tracks revoked certs"
    echo "  [DB]  Certificate database - tracks issued certificates"
    echo ""
    echo "Next steps:"
    echo "  Run pc8-certificate-request.sh to issue client certificates."
    echo "================================="
}

# --- Main execution ---
echo "=============================================="
echo " PRACTICAL CASE 7: CERTIFICATE AUTHORITY (CA)"
echo "=============================================="
echo ""
echo "A Certificate Authority (CA) is the trust anchor of a PKI."
echo "It issues digital certificates that bind identities to public keys."
echo "This lab creates an equivalent to the textbook's Windows CA using OpenSSL."
echo ""

initialize_ca_structure
generate_ca_key
generate_ca_certificate
display_ca_certificate
generate_initial_crl
show_pki_summary

echo "=============================================="