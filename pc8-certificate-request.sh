#!/usr/bin/env bash
# =============================================================================
# pc8-certificate-request.sh
# Certificate Request, Issuance, and Revocation
# SRE Cryptography Guide - Practical Case 8
# =============================================================================
# Description:
#   Demonstrates the full certificate lifecycle:
#   1. Generate a key pair for the end-entity
#   2. Create a Certificate Signing Request (CSR)
#   3. Submit CSR to CA and receive signed certificate
#   4. Verify the issued certificate
#   5. Revoke the certificate and update the CRL
#   Corresponds to Caso Practico 8 from the textbook (Linux OpenSSL version).
# Prerequisites:
#   - openssl installed
#   - CA created by pc7-certificate-authority.sh
# Usage:
#   bash pc8-certificate-request.sh [ca_dir] [user_name] [user_email]
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------
# Configuration
# ---------------------------------------------------------
CA_DIR="${1:-/tmp/ca-SiTourCA}"
USER_NAME="${2:-Fernando}"
USER_EMAIL="${3:-fernando@sitour.com}"
USER_DEPT="${4:-Ventas}"

# Derived paths
CA_CONF="${CA_DIR}/openssl.cnf"
CA_CERT="${CA_DIR}/certs/ca.cert.pem"
CA_KEY="${CA_DIR}/private/ca.key.pem"
USER_DIR="${CA_DIR}/requests/${USER_NAME}"
USER_KEY="${USER_DIR}/${USER_NAME}.key.pem"
USER_CSR="${USER_DIR}/${USER_NAME}.csr.pem"
USER_CERT="${USER_DIR}/${USER_NAME}.cert.pem"
USER_SUBJECT="/C=ES/ST=Segovia/L=Fuentemilanos/O=SITOUR SA/OU=${USER_DEPT}/CN=${USER_NAME}/emailAddress=${USER_EMAIL}"

echo "============================================================"
echo " PC8 - Certificate Request and Revocation"
echo " SRE Cryptography Automation Guide"
echo "============================================================"
echo ""
echo "[CONFIG]"
echo "  CA Directory : ${CA_DIR}"
echo "  User         : ${USER_NAME} <${USER_EMAIL}>"
echo "  Department   : ${USER_DEPT}"
echo "  Subject      : ${USER_SUBJECT}"
echo ""

# ---------------------------------------------------------
# Validation
# ---------------------------------------------------------
if ! command -v openssl &>/dev/null; then
    echo "[ERROR] openssl not found."
    exit 1
fi

if [[ ! -f "${CA_CONF}" ]]; then
    echo "[ERROR] CA configuration not found: ${CA_CONF}"
    echo "        Run pc7-certificate-authority.sh first."
    exit 1
fi

if [[ ! -f "${CA_CERT}" ]]; then
    echo "[ERROR] CA certificate not found: ${CA_CERT}"
    exit 1
fi

echo "[OK]    CA configuration verified."
echo ""

# ---------------------------------------------------------
# Step 1: Create user directory
# ---------------------------------------------------------
echo "[STEP 1] Creating user certificate directory..."
mkdir -p "${USER_DIR}"
chmod 700 "${USER_DIR}"
echo "[OK]    Created: ${USER_DIR}"
echo ""

# ---------------------------------------------------------
# Step 2: Generate user private key
# ---------------------------------------------------------
echo "[STEP 2] Generating user private key (RSA 4096-bit)..."

openssl genrsa \
    -out "${USER_KEY}" \
    4096

chmod 400 "${USER_KEY}"
echo "[OK]    User private key: ${USER_KEY}"
echo ""

# ---------------------------------------------------------
# Step 3: Generate Certificate Signing Request (CSR)
# ---------------------------------------------------------
echo "[STEP 3] Generating Certificate Signing Request (CSR)..."
echo "[INFO]   Subject: ${USER_SUBJECT}"

openssl req \
    -new \
    -sha256 \
    -key "${USER_KEY}" \
    -subj "${USER_SUBJECT}" \
    -out "${USER_CSR}"

echo "[OK]    CSR created: ${USER_CSR}"
echo ""

echo "[INFO]  CSR contents (what the user sends to the CA):"
openssl req -noout -text -in "${USER_CSR}" | grep -E "(Subject:|Public-Key:|Signature Algorithm)"
echo ""

# ---------------------------------------------------------
# Step 4: CA signs the CSR (issuance)
# ---------------------------------------------------------
echo "[STEP 4] CA signing the CSR (certificate issuance)..."
echo "[INFO]   This simulates the CA administrator approving and signing the request."

openssl ca \
    -config "${CA_CONF}" \
    -extensions usr_cert \
    -days 375 \
    -notext \
    -md sha256 \
    -batch \
    -in "${USER_CSR}" \
    -out "${USER_CERT}" 2>&1

echo "[OK]    Certificate issued: ${USER_CERT}"
chmod 444 "${USER_CERT}"
echo ""

# ---------------------------------------------------------
# Step 5: Verify the issued certificate
# ---------------------------------------------------------
echo "[STEP 5] Verifying the issued certificate..."

echo "[INFO]  Certificate details:"
openssl x509 -noout -text -in "${USER_CERT}" | grep -E "(Subject:|Issuer:|Not Before|Not After|CA:|Email)"
echo ""

echo "[INFO]  Chain verification against CA:"
openssl verify -CAfile "${CA_CERT}" "${USER_CERT}"
echo ""

# ---------------------------------------------------------
# Step 6: Export certificate in various formats
# ---------------------------------------------------------
echo "[STEP 6] Exporting certificate in DER format (for browser import)..."
USER_CERT_DER="${USER_DIR}/${USER_NAME}.cert.der"
openssl x509 -in "${USER_CERT}" -outform DER -out "${USER_CERT_DER}"
echo "[OK]    DER format: ${USER_CERT_DER}"
echo ""

# ---------------------------------------------------------
# Step 7: Certificate revocation
# ---------------------------------------------------------
echo "[STEP 7] Demonstrating certificate revocation..."
echo "[INFO]   Reason codes:"
echo "         0 = Unspecified"
echo "         1 = keyCompromise"
echo "         2 = CACompromise"
echo "         3 = affiliationChanged"
echo "         4 = superseded"
echo "         5 = cessationOfOperation"
echo "         6 = certificateHold"
echo ""

# Get serial number
CERT_SERIAL=$(openssl x509 -noout -serial -in "${USER_CERT}" | cut -d= -f2)
echo "[INFO]  Revoking certificate with serial: ${CERT_SERIAL}"
echo "[INFO]  Revocation reason: keyCompromise (1)"
echo ""

openssl ca \
    -config "${CA_CONF}" \
    -revoke "${USER_CERT}" \
    -crl_reason keyCompromise \
    -batch 2>&1

echo "[OK]    Certificate revoked."
echo ""

# ---------------------------------------------------------
# Step 8: Update and verify CRL
# ---------------------------------------------------------
echo "[STEP 8] Updating Certificate Revocation List (CRL)..."

openssl ca \
    -config "${CA_CONF}" \
    -gencrl \
    -out "${CA_DIR}/crl/ca.crl.pem" 2>&1

echo "[OK]    CRL updated: ${CA_DIR}/crl/ca.crl.pem"
echo ""

echo "[INFO]  Revoked certificates in CRL:"
openssl crl -noout -text -in "${CA_DIR}/crl/ca.crl.pem" | grep -A3 "Revoked Certificates"
echo ""

# Verify revoked cert is now rejected
echo "[INFO]  Verifying revoked certificate (should fail):"
openssl verify \
    -CAfile "${CA_CERT}" \
    -crl_check \
    -CRLfile "${CA_DIR}/crl/ca.crl.pem" \
    "${USER_CERT}" 2>&1 || echo "[OK]    Correctly rejected: revoked certificate is no longer valid."

echo ""

# ---------------------------------------------------------
# Step 9: Summary
# ---------------------------------------------------------
echo "[SUMMARY]"
echo "  User            : ${USER_NAME} <${USER_EMAIL}>"
echo "  Private Key     : ${USER_KEY}"
echo "  CSR             : ${USER_CSR}"
echo "  Certificate     : ${USER_CERT}"
echo "  Certificate DER : ${USER_CERT_DER}"
echo "  Serial Number   : ${CERT_SERIAL}"
echo "  Status          : REVOKED (keyCompromise)"
echo "  CRL             : ${CA_DIR}/crl/ca.crl.pem"
echo ""
echo "[LIFECYCLE STAGES DEMONSTRATED]"
echo "  1. Key generation -> 2. CSR creation -> 3. CA signing"
echo "  4. Certificate issuance -> 5. Verification -> 6. Revocation"
echo "  7. CRL update -> 8. Revoked cert rejection"
echo ""
echo "[SRE NOTE]"
echo "  In production, use OCSP (Online Certificate Status Protocol)"
echo "  for real-time revocation checking instead of CRL polling."
echo "  Automate CRL publication to a publicly accessible URL."
echo "============================================================"