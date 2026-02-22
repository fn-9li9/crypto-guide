#!/bin/bash
# pc8-certificate-request.sh
# Practical Case 8: Certificate Request and Revocation
# Demonstrates the full certificate lifecycle:
#   1. Generate user key pair
#   2. Create Certificate Signing Request (CSR)
#   3. CA signs the CSR -> issues certificate
#   4. Install/verify certificate
#   5. Revoke certificate and update CRL

set -euo pipefail

CA_DIR="/workspace/pki/ca"
USER_DIR="/workspace/pki/users"
CA_PASSPHRASE="CaRootPassphrase2024!"
USER_PASSPHRASE="UserCertPass2024!"

# User information (equivalent to textbook's Fernando/Macarena example)
FERNANDO_KEY="$USER_DIR/fernando/fernando.key"
FERNANDO_CSR="$USER_DIR/fernando/fernando.csr"
FERNANDO_CERT="$USER_DIR/fernando/fernando.crt"
FERNANDO_P12="$USER_DIR/fernando/fernando.p12"

check_ca_installed() {
    echo "--- Verifying CA installation ---"
    if [ ! -f "$CA_DIR/certs/ca.crt" ]; then
        echo "ERROR: CA not found. Run pc7-certificate-authority.sh first."
        exit 1
    fi
    echo "CA found: $CA_DIR/certs/ca.crt"
    echo "CA subject: $(openssl x509 -in "$CA_DIR/certs/ca.crt" -noout -subject)"
}

generate_user_key() {
    echo ""
    echo "--- Step 1: Generating User Private Key ---"
    echo "User: Fernando (equivalent to textbook case)"

    mkdir -p "$USER_DIR/fernando"

    # Generate RSA 4096 private key for user
    openssl genrsa \
        -aes256 \
        -passout "pass:$USER_PASSPHRASE" \
        -out "$FERNANDO_KEY" \
        4096

    chmod 400 "$FERNANDO_KEY"
    echo "User private key: $FERNANDO_KEY"
    echo "Key protected with passphrase (never share this key)."
}

generate_csr() {
    echo ""
    echo "--- Step 2: Creating Certificate Signing Request (CSR) ---"
    echo "The CSR contains the user's public key and identity information."
    echo "The CSR is sent to the CA for signing."
    echo "NOTE: C, ST and O must match the CA (policy_strict). Using policy_loose instead."

    # Subject fields must satisfy the CA policy defined in openssl.cnf.
    # policy_strict requires C, ST and O to match the CA exactly.
    # We switch to policy_loose (optional matching) so the user can have
    # different locality/department values.
    openssl req \
        -new \
        -sha256 \
        -key "$FERNANDO_KEY" \
        -passin "pass:$USER_PASSPHRASE" \
        -subj "/C=ES/ST=Segovia/L=Cuenca/O=SiTour SA/OU=Ventas/CN=Fernando/emailAddress=fernando@sitour.com" \
        -out "$FERNANDO_CSR"

    echo "CSR created: $FERNANDO_CSR"
    echo ""
    echo "CSR details:"
    openssl req -in "$FERNANDO_CSR" -noout -text | grep -E "(Subject:|Public Key|Signature Algorithm)" | head -5
}

sign_certificate() {
    echo ""
    echo "--- Step 3: CA Signs the Certificate ---"
    echo "The CA verifies the CSR and issues a signed certificate."
    echo "This is the Registration Authority (RA) + CA process combined."

    # Use policy_loose so CSR fields don't need to exactly match the CA DN.
    # Remove 2>/dev/null so any signing error is shown to the operator.
    openssl ca \
        -config "$CA_DIR/openssl.cnf" \
        -extensions usr_cert \
        -policy policy_loose \
        -days 365 \
        -notext \
        -md sha256 \
        -batch \
        -passin "pass:$CA_PASSPHRASE" \
        -in "$FERNANDO_CSR" \
        -out "$FERNANDO_CERT"

    if [ $? -ne 0 ]; then
        echo "ERROR: Certificate signing failed. Check CA configuration and CSR subject fields."
        exit 1
    fi

    echo "Certificate issued: $FERNANDO_CERT"
    echo ""
    echo "Certificate information:"
    openssl x509 -in "$FERNANDO_CERT" -noout -text | grep -E "(Subject:|Issuer:|Not Before|Not After|Serial Number)" | head -6
}

verify_certificate_chain() {
    echo ""
    echo "--- Step 4: Verify Certificate Against CA ---"
    echo "Verifies the certificate chain: user cert -> root CA"

    openssl verify \
        -CAfile "$CA_DIR/certs/ca.crt" \
        "$FERNANDO_CERT"

    echo ""
    echo "Certificate fingerprint (for out-of-band verification):"
    openssl x509 -in "$FERNANDO_CERT" -noout -fingerprint -sha256
}

export_pkcs12() {
    echo ""
    echo "--- Step 5: Export as PKCS#12 Bundle ---"
    echo "PKCS#12 bundles the certificate + private key in one file."
    echo "This format is used for importing into mail clients (Outlook, Thunderbird)."
    echo "Equivalent to the certificate Fernando installs in the textbook."

    openssl pkcs12 \
        -export \
        -inkey "$FERNANDO_KEY" \
        -in "$FERNANDO_CERT" \
        -certfile "$CA_DIR/certs/ca.crt" \
        -passin "pass:$USER_PASSPHRASE" \
        -passout "pass:$USER_PASSPHRASE" \
        -out "$FERNANDO_P12"

    echo "PKCS#12 bundle: $FERNANDO_P12"
    echo "This file contains: certificate + private key + CA chain"
    echo "Import this file into your mail client to sign/encrypt emails."
}

revoke_certificate() {
    echo ""
    echo "--- Step 6: Certificate Revocation ---"
    echo "Revocation invalidates a certificate before its expiry date."
    echo "Reasons: key compromise, user left organization, superseded."

    # Revoke with reason "keyCompromise" (code 1)
    openssl ca \
        -config "$CA_DIR/openssl.cnf" \
        -revoke "$FERNANDO_CERT" \
        -crl_reason keyCompromise \
        -passin "pass:$CA_PASSPHRASE" 2>/dev/null || true

    echo "Certificate revoked."

    # Update CRL
    openssl ca \
        -config "$CA_DIR/openssl.cnf" \
        -gencrl \
        -passin "pass:$CA_PASSPHRASE" \
        -out "$CA_DIR/crl/ca.crl" 2>/dev/null

    echo "Certificate Revocation List updated: $CA_DIR/crl/ca.crl"
    echo ""
    echo "CRL contents:"
    openssl crl -in "$CA_DIR/crl/ca.crl" -noout -text | head -20
}

verify_revoked_certificate() {
    echo ""
    echo "--- Step 7: Verify Revoked Certificate Status ---"

    # Convert CRL to PEM for combined verification
    openssl verify \
        -CAfile "$CA_DIR/certs/ca.crt" \
        -crl_check \
        -CRLfile "$CA_DIR/crl/ca.crl" \
        "$FERNANDO_CERT" 2>&1 || echo "(Expected: certificate has been revoked)"
}

show_cert_database() {
    echo ""
    echo "--- Certificate Database (CA Records) ---"
    echo "Format: Status | Expiry | Revocation Date | Serial | Subject"
    echo ""
    cat "$CA_DIR/index.txt"
    echo ""
    echo "Status codes: V=Valid, R=Revoked, E=Expired"
}

show_revocation_codes() {
    echo ""
    echo "--- Certificate Revocation Reason Codes ---"
    printf "%-5s %-35s\n" "Code" "Reason"
    printf "%-5s %-35s\n" "----" "------"
    printf "%-5s %-35s\n" "0" "unspecified"
    printf "%-5s %-35s\n" "1" "keyCompromise"
    printf "%-5s %-35s\n" "2" "cACompromise"
    printf "%-5s %-35s\n" "3" "affiliationChanged"
    printf "%-5s %-35s\n" "4" "superseded"
    printf "%-5s %-35s\n" "5" "cessationOfOperation"
    printf "%-5s %-35s\n" "6" "certificateHold"
}

# --- Main execution ---
echo "=============================================="
echo " PRACTICAL CASE 8: CERTIFICATE REQUEST & REVOCATION"
echo "=============================================="
echo ""
echo "Full PKI certificate lifecycle demonstration:"
echo "  User generates key -> Creates CSR -> CA signs -> Certificate issued"
echo "  -> Certificate verified -> Certificate revoked -> CRL updated"
echo ""

check_ca_installed
generate_user_key
generate_csr
sign_certificate
verify_certificate_chain
export_pkcs12
show_cert_database
revoke_certificate
verify_revoked_certificate
show_revocation_codes

echo ""
echo "Certificate lifecycle complete."
echo "The PKCS#12 file ($FERNANDO_P12) can be imported into"
echo "mail clients for S/MIME email encryption and digital signing."
echo "=============================================="