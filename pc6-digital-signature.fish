#!/usr/bin/env fish
# =============================================================================
# pc6-digital-signature.fish
# Digital Document Signature with GPG
# SRE Cryptography Guide - Practical Case 6
# =============================================================================
# Description:
#   Signs a document using three GPG methods:
#   --clearsign : text remains readable, signature appended
#   -s          : binary signed output (compressed)
#   -b          : detached signature in separate file
#   Then verifies all signatures.
#   Process mirrors the textbook's Caso Practico 6.
# Prerequisites:
#   - gnupg installed
#   - A GPG private key in keyring (run pc3-key-generation.fish first)
# Usage:
#   fish pc6-digital-signature.fish [document] [passphrase]
# =============================================================================

set INPUT_DOC $argv[1]
set PASSPHRASE $argv[2]
set WORK_DIR "/tmp/pc6-signatures"

mkdir -p "$WORK_DIR"

# Create demo document if not provided
if test -z "$INPUT_DOC"
    set INPUT_DOC "$WORK_DIR/Documento_secreto.txt"
    echo "Documento secreto que se enviara firmado digitalmente." > "$INPUT_DOC"
    echo "De esta manera nos aseguramos la autenticidad y la integridad del mismo." >> "$INPUT_DOC"
    echo "" >> "$INPUT_DOC"
    echo "Empresa: SiTour - Departamento de Seguridad Informatica" >> "$INPUT_DOC"
    echo "Fecha: "(date) >> "$INPUT_DOC"
end

# Use test passphrase if none provided
if test -z "$PASSPHRASE"
    set PASSPHRASE "SRE-Demo-Passphrase-2024!"
end

echo "============================================================"
echo " PC6 - Digital Document Signature"
echo " SRE Cryptography Automation Guide"
echo "============================================================"
echo ""

# ---------------------------------------------------------
# Step 1: Display document to be signed
# ---------------------------------------------------------
echo "[STEP 1] Document to sign: $INPUT_DOC"
echo "---"
cat "$INPUT_DOC"
echo "---"
echo ""

# ---------------------------------------------------------
# Step 2: Verify a signing key is available
# ---------------------------------------------------------
echo "[STEP 2] Checking for available signing keys..."
set KEY_COUNT (gpg --list-secret-keys --with-colons 2>/dev/null | grep "^sec" | wc -l | string trim)

if test "$KEY_COUNT" -eq 0
    echo "[ERROR] No private keys found. Run pc3-key-generation.fish first."
    exit 1
end

echo "[OK]    Found $KEY_COUNT private key(s) available for signing."
echo ""
gpg --list-secret-keys --keyid-format LONG
echo ""

# Detect first available signing key UID
set SIGNER_UID (gpg --list-secret-keys --with-colons 2>/dev/null | grep "^uid" | head -1 | awk -F: '{print $10}')
echo "[INFO]  Signing as: $SIGNER_UID"
echo ""

# ---------------------------------------------------------
# Step 3: Method A - Clearsign (readable text + signature)
# ---------------------------------------------------------
set OUT_CLEARSIGN "$WORK_DIR/Documento_secreto.asc"
echo "[STEP 3A] Signing with --clearsign (text remains readable)..."

gpg \
    --batch \
    --yes \
    --pinentry-mode loopback \
    --passphrase "$PASSPHRASE" \
    --clearsign \
    --output "$OUT_CLEARSIGN" \
    "$INPUT_DOC"

if test $status -eq 0
    echo "[OK]    Clearsign output: $OUT_CLEARSIGN"
    echo ""
    echo "[INFO]  Clearsign content (text + embedded signature):"
    echo "---"
    cat "$OUT_CLEARSIGN"
    echo "---"
else
    echo "[ERROR] Clearsign failed."
    exit 1
end

echo ""

# ---------------------------------------------------------
# Step 4: Method B - Binary signature (-s with armor)
# ---------------------------------------------------------
set OUT_SIGNED "$WORK_DIR/Documento_secreto_signed.asc"
echo "[STEP 3B] Signing with -s --armor (binary signature, ASCII output)..."

gpg \
    --batch \
    --yes \
    --pinentry-mode loopback \
    --passphrase "$PASSPHRASE" \
    --sign \
    --armor \
    --output "$OUT_SIGNED" \
    "$INPUT_DOC"

if test $status -eq 0
    echo "[OK]    Binary-signed output: $OUT_SIGNED"
    echo ""
    echo "[INFO]  Binary-signed content (document + signature, compressed):"
    echo "---"
    cat "$OUT_SIGNED"
    echo "---"
else
    echo "[ERROR] Binary signature failed."
    exit 1
end

echo ""

# ---------------------------------------------------------
# Step 5: Method C - Detached signature (-b)
# ---------------------------------------------------------
set OUT_DETACHED "$WORK_DIR/Documento_secreto.sig"
echo "[STEP 3C] Signing with -b --armor (detached signature in separate file)..."

gpg \
    --batch \
    --yes \
    --pinentry-mode loopback \
    --passphrase "$PASSPHRASE" \
    --detach-sign \
    --armor \
    --output "$OUT_DETACHED" \
    "$INPUT_DOC"

if test $status -eq 0
    echo "[OK]    Detached signature: $OUT_DETACHED"
    echo ""
    echo "[INFO]  Detached signature content (signature only, document separate):"
    echo "---"
    cat "$OUT_DETACHED"
    echo "---"
else
    echo "[ERROR] Detached signature failed."
    exit 1
end

echo ""

# ---------------------------------------------------------
# Step 6: Verify all signatures
# ---------------------------------------------------------
echo "[STEP 4] Verifying all signatures..."
echo ""

echo "[VERIFY A] --clearsign signature:"
gpg \
    --batch \
    --pinentry-mode loopback \
    --verify "$OUT_CLEARSIGN" 2>&1
echo ""

echo "[VERIFY B] Binary signed file:"
set RECOVERED "$WORK_DIR/Documento_recovered.txt"
gpg \
    --batch \
    --yes \
    --pinentry-mode loopback \
    --output "$RECOVERED" \
    --decrypt "$OUT_SIGNED" 2>&1
echo ""

echo "[VERIFY C] Detached signature:"
gpg \
    --batch \
    --pinentry-mode loopback \
    --verify "$OUT_DETACHED" "$INPUT_DOC" 2>&1
echo ""

# ---------------------------------------------------------
# Summary
# ---------------------------------------------------------
echo "[SUMMARY]"
echo "  Original document   : $INPUT_DOC"
echo "  Clearsign (.asc)    : $OUT_CLEARSIGN"
echo "  Binary signed (.asc): $OUT_SIGNED"
echo "  Detached sig (.sig) : $OUT_DETACHED"
echo "  Recovered document  : $RECOVERED"
echo ""
echo "[PROCESS EXPLANATION]"
echo "  1. GPG computes SHA hash of the document"
echo "  2. Hash is encrypted with the PRIVATE key of the signer"
echo "  3. Result is the digital signature"
echo "  4. Verification: decrypt signature with PUBLIC key -> compare hash"
echo "  5. If hashes match -> document is authentic and unmodified"
echo ""
echo "[NOTE] The signature proves WHO signed and that the document was NOT modified."
echo "       It does NOT encrypt the document content (use -se to sign + encrypt)."
echo "============================================================"