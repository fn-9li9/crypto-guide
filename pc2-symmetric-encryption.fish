#!/usr/bin/env fish
# =============================================================================
# pc2-symmetric-encryption.fish
# Symmetric Encryption with GnuPG (GNU Privacy Guard)
# SRE Cryptography Guide - Practical Case 2
# =============================================================================
# Description:
#   Demonstrates symmetric (private key) encryption and decryption using GPG.
#   Uses --batch and --pinentry-mode loopback for full automation.
#   Produces both binary (.gpg) and ASCII-armored (.asc) outputs.
# Prerequisites:
#   - gnupg installed (available via: nix-shell -p gnupg)
# Usage:
#   fish pc2-symmetric-encryption.fish [passphrase] [input_file]
# =============================================================================

# ---------------------------------------------------------
# Configuration
# ---------------------------------------------------------
set PASSPHRASE $argv[1]
set INPUT_FILE $argv[2]
set WORK_DIR "/tmp/pc2-symmetric"

# Use defaults if not provided
if test -z "$PASSPHRASE"
    set PASSPHRASE "SRE-Demo-Passphrase-2024!"
end

if test -z "$INPUT_FILE"
    set INPUT_FILE "$WORK_DIR/Documento_Secreto.txt"
end

# ---------------------------------------------------------
# Setup working directory
# ---------------------------------------------------------
mkdir -p $WORK_DIR

echo "============================================================"
echo " PC2 - Symmetric Encryption with GnuPG"
echo " SRE Cryptography Automation Guide"
echo "============================================================"
echo ""

# ---------------------------------------------------------
# Step 1: Create sample document if it does not exist
# ---------------------------------------------------------
if not test -f "$INPUT_FILE"
    echo "[STEP 1] Creating sample document: $INPUT_FILE"
    echo "Documento confidencial para cifrado simetrico." > $INPUT_FILE
    echo "Este archivo contiene informacion sensible de la empresa SiTour." >> $INPUT_FILE
    echo "Fecha: "(date) >> $INPUT_FILE
    echo "Autor: Administrador de Seguridad" >> $INPUT_FILE
    echo "[INFO]  Document created successfully."
else
    echo "[STEP 1] Using existing document: $INPUT_FILE"
end

echo ""
echo "[INFO]  Plaintext content:"
echo "---"
cat $INPUT_FILE
echo "---"
echo ""

# ---------------------------------------------------------
# Step 2: Symmetric encryption - binary output (.gpg)
# ---------------------------------------------------------
set OUTPUT_GPG "$INPUT_FILE.gpg"
echo "[STEP 2] Encrypting to binary format: $OUTPUT_GPG"

gpg \
    --batch \
    --yes \
    --pinentry-mode loopback \
    --passphrase "$PASSPHRASE" \
    --symmetric \
    --cipher-algo AES256 \
    --output "$OUTPUT_GPG" \
    "$INPUT_FILE"

if test $status -eq 0
    echo "[OK]    Binary encrypted file created: $OUTPUT_GPG"
    echo "[INFO]  File size: "(wc -c < $OUTPUT_GPG)" bytes (binary, not human-readable)"
else
    echo "[ERROR] Binary encryption failed."
    exit 1
end

echo ""

# ---------------------------------------------------------
# Step 3: Symmetric encryption - ASCII armor output (.asc)
# ---------------------------------------------------------
set OUTPUT_ASC "$INPUT_FILE.asc"
echo "[STEP 3] Encrypting to ASCII-armored format: $OUTPUT_ASC"

gpg \
    --batch \
    --yes \
    --pinentry-mode loopback \
    --passphrase "$PASSPHRASE" \
    --symmetric \
    --cipher-algo AES256 \
    --armor \
    --output "$OUTPUT_ASC" \
    "$INPUT_FILE"

if test $status -eq 0
    echo "[OK]    ASCII-armored encrypted file created: $OUTPUT_ASC"
    echo ""
    echo "[INFO]  ASCII-armored content (human-readable PGP block):"
    echo "---"
    cat $OUTPUT_ASC
    echo "---"
else
    echo "[ERROR] ASCII armor encryption failed."
    exit 1
end

echo ""

# ---------------------------------------------------------
# Step 4: Verify encryption by decrypting
# ---------------------------------------------------------
set DECRYPTED_FILE "$WORK_DIR/Documento_Secreto_recovered.txt"
echo "[STEP 4] Verifying: decrypting $OUTPUT_ASC -> $DECRYPTED_FILE"

gpg \
    --batch \
    --yes \
    --pinentry-mode loopback \
    --passphrase "$PASSPHRASE" \
    --output "$DECRYPTED_FILE" \
    --decrypt "$OUTPUT_ASC"

if test $status -eq 0
    echo "[OK]    Decryption successful."
    echo ""
    echo "[INFO]  Recovered content:"
    echo "---"
    cat $DECRYPTED_FILE
    echo "---"

    # Integrity check
    if diff -q "$INPUT_FILE" "$DECRYPTED_FILE" > /dev/null 2>&1
        echo ""
        echo "[OK]    Integrity check PASSED: Original and recovered files are identical."
    else
        echo ""
        echo "[WARN]  Integrity check FAILED: Files differ."
    end
else
    echo "[ERROR] Decryption failed. Check passphrase."
    exit 1
end

echo ""
echo "[SUMMARY]"
echo "  Plaintext   : $INPUT_FILE"
echo "  Binary GPG  : $OUTPUT_GPG"
echo "  ASCII GPG   : $OUTPUT_ASC"
echo "  Recovered   : $DECRYPTED_FILE"
echo "  Algorithm   : AES-256 (symmetric)"
echo ""
echo "[NOTE] In production environments, never hardcode passphrases."
echo "       Use secret managers (Vault, AWS Secrets Manager, etc.)."
echo "============================================================"