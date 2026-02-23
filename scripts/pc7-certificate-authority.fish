#!/usr/bin/env fish
# pc7-certificate-authority.fish
# Practical Case 7: Root Certificate Authority Installation
# Creates a fully functional PKI CA equivalent to the textbook's Windows CA.

set CA_DIR "/workspace/pki/ca"
set CA_PASSPHRASE "CaRootPassphrase2026!"
set CA_SUBJECT "/C=PE/ST=Lima/L=Lima/O=SiTour SA/OU=Division de certificados/CN=SiTourCA/emailAddress=stella.sre.inc@gmail.com"
set CA_KEY "$CA_DIR/private/ca.key"
set CA_CERT "$CA_DIR/certs/ca.crt"
set CA_CRL "$CA_DIR/crl/ca.crl"

function create_directory_structure
    echo ""
    echo "--- Creating PKI Directory Structure ---"

    mkdir -p "$CA_DIR/certs"
    mkdir -p "$CA_DIR/private"
    mkdir -p "$CA_DIR/newcerts"
    mkdir -p "$CA_DIR/crl"
    chmod 700 "$CA_DIR/private"

    # Initialize certificate database
    touch "$CA_DIR/index.txt"
    echo "01" > "$CA_DIR/serial"
    echo "01" > "$CA_DIR/crlnumber"

    echo "PKI structure created at: $CA_DIR"
    echo "  certs/    - issued certificates"
    echo "  private/  - CA private key (chmod 700)"
    echo "  newcerts/ - copies of issued certs (by serial)"
    echo "  crl/      - certificate revocation lists"
    echo "  index.txt - certificate database"
    echo "  serial    - next serial number"
end

function create_openssl_config
    echo ""
    echo "--- Creating OpenSSL Configuration ---"

    # Write openssl.cnf using python3 to avoid heredoc issues in Fish
    python3 -c "
config = '''[ ca ]
default_ca = CA_default

[ CA_default ]
dir               = $CA_DIR
certs             = \$dir/certs
crl_dir           = \$dir/crl
new_certs_dir     = \$dir/newcerts
database          = \$dir/index.txt
serial            = \$dir/serial
RANDFILE          = \$dir/private/.rand
private_key       = \$dir/private/ca.key
certificate       = \$dir/certs/ca.crt
crlnumber         = \$dir/crlnumber
crl               = \$dir/crl/ca.crl
crl_extensions    = crl_ext
default_crl_days  = 30
default_md        = sha256
name_opt          = ca_default
cert_opt          = ca_default
default_days      = 375
preserve          = no
policy            = policy_loose

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
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ usr_cert ]
basicConstraints = CA:FALSE
nsCertType = client, email
nsComment = \"OpenSSL Generated Client Certificate\"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, emailProtection

[ server_cert ]
basicConstraints = CA:FALSE
nsCertType = server
nsComment = \"OpenSSL Generated Server Certificate\"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth

[ crl_ext ]
authorityKeyIdentifier=keyid:always

[ ocsp ]
basicConstraints = CA:FALSE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, OCSPSigning
'''
with open('$CA_DIR/openssl.cnf', 'w') as f:
    f.write(config)
print('openssl.cnf written')
"
end

function generate_ca_key
    echo ""
    echo "--- Generating CA Private Key ---"
    echo "Algorithm: RSA 4096 bits, encrypted with AES-256"
    echo "This key MUST be stored offline in production (HSM or air-gapped system)"
    echo ""

    openssl genrsa \
        -aes256 \
        -passout "pass:$CA_PASSPHRASE" \
        -out "$CA_KEY" \
        4096

    chmod 400 "$CA_KEY"
    echo ""
    echo "CA private key: $CA_KEY (chmod 400 - read only by owner)"
end

function generate_ca_certificate
    echo ""
    echo "--- Generating Self-Signed CA Certificate ---"
    echo "Validity: 3650 days (10 years)"
    echo "Subject:  $CA_SUBJECT"
    echo ""

    openssl req \
        -new \
        -x509 \
        -days 3650 \
        -sha256 \
        -extensions v3_ca \
        -key "$CA_KEY" \
        -passin "pass:$CA_PASSPHRASE" \
        -subj "$CA_SUBJECT" \
        -out "$CA_CERT"

    echo ""
    echo "CA certificate: $CA_CERT"
    echo ""
    echo "--- Certificate Details ---"
    openssl x509 -in "$CA_CERT" -noout -text \
        | grep -E "(Subject:|Issuer:|Not Before|Not After|Serial Number)" \
        | head -6
end

function generate_initial_crl
    echo ""
    echo "--- Generating Initial Certificate Revocation List (CRL) ---"

    openssl ca \
        -config "$CA_DIR/openssl.cnf" \
        -gencrl \
        -passin "pass:$CA_PASSPHRASE" \
        -out "$CA_CRL" 2>/dev/null

    echo "CRL generated: $CA_CRL"
    echo ""
    echo "CRL details:"
    openssl crl -in "$CA_CRL" -noout -text \
        | grep -E "(Issuer:|Last Update:|Next Update:)" \
        | head -4
end

function show_ca_fingerprints
    echo ""
    echo "--- CA Certificate Fingerprints ---"
    echo "Share these fingerprints out-of-band to allow clients to verify the CA."
    echo ""
    echo "SHA-256:"
    openssl x509 -in "$CA_CERT" -noout -fingerprint -sha256
    echo ""
    echo "SHA-1 (legacy):"
    openssl x509 -in "$CA_CERT" -noout -fingerprint -sha1
end

function show_pki_summary
    echo ""
    echo "=== PKI INSTALLATION SUMMARY ==="
    echo ""
    echo "CA Name:    SiTourCA"
    echo "CA Cert:    $CA_CERT"
    echo "CA Key:     $CA_KEY"
    echo "CA CRL:     $CA_CRL"
    echo "Config:     $CA_DIR/openssl.cnf"
    echo ""
    echo "This CA can now:"
    echo "  - Issue user certificates (usr_cert extension)"
    echo "  - Issue server/TLS certificates (server_cert extension)"
    echo "  - Revoke certificates and publish CRL"
    echo ""
    echo "Next step: Run pc8-certificate-request.fish to issue a user certificate."
    echo "================================="
end

# --- Main execution ---
echo "=============================================="
echo " PRACTICAL CASE 7: CERTIFICATE AUTHORITY"
echo "=============================================="
echo ""
echo "Installing a root CA equivalent to the textbook's Windows CA (SiTourCA)."
echo "Implementation: OpenSSL on Linux (cross-platform, scriptable, reproducible)."
echo ""

create_directory_structure
and create_openssl_config
and generate_ca_key
and generate_ca_certificate
and generate_initial_crl
and show_ca_fingerprints
and show_pki_summary
