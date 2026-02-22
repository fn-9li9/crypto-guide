#!/usr/bin/env fish
# pc2-symmetric-encryption.fish
# Practical Case 2: Symmetric Encryption with GnuPG
# Demonstrates AES-256 symmetric (private key) encryption and decryption
# Uses --batch and --pinentry-mode loopback for fully non-interactive operation

set PASSPHRASE "LabSymmetricKey2024!"
set ORIGINAL_FILE "/workspace/samples/secret_document.txt"
set ENCRYPTED_FILE "/workspace/samples/secret_document.txt.gpg"
set DECRYPTED_FILE "/workspace/samples/secret_document_decrypted.txt"
set ASCII_FILE "/workspace/samples/secret_document.asc"

# Ensure samples directory exists
mkdir -p /workspace/samples

# Create a sample document to encrypt
function create_sample_document
    echo "Creating sample confidential document..."
    echo "CONFIDENTIAL DOCUMENT" > "$ORIGINAL_FILE"
    echo "========================" >> "$ORIGINAL_FILE"
    echo "This document contains sensitive information." >> "$ORIGINAL_FILE"
    echo "Date: "(date) >> "$ORIGINAL_FILE"
    echo "Author: stella" >> "$ORIGINAL_FILE"
    echo "Content: Symmetric encryption demonstration using GnuPG AES-256." >> "$ORIGINAL_FILE"
    echo "Document created successfully: $ORIGINAL_FILE"
end

function encrypt_symmetric
    echo ""
    echo "--- SYMMETRIC ENCRYPTION (Binary output) ---"
    # Encrypt with AES256, batch mode, loopback pinentry - non-interactive
    gpg --batch \
        --yes \
        --pinentry-mode loopback \
        --passphrase "$PASSPHRASE" \
        --symmetric \
        --cipher-algo AES256 \
        --output "$ENCRYPTED_FILE" \
        "$ORIGINAL_FILE"

    if test $status -eq 0
        echo "Encrypted file created: $ENCRYPTED_FILE"
        echo "File size comparison:"
        echo "  Original : "(wc -c < "$ORIGINAL_FILE")" bytes"
        echo "  Encrypted: "(wc -c < "$ENCRYPTED_FILE")" bytes"
    else
        echo "ERROR: Encryption failed."
        return 1
    end
end

function encrypt_symmetric_ascii
    echo ""
    echo "--- SYMMETRIC ENCRYPTION (ASCII-armored output) ---"
    # ASCII-armored output is useful for embedding in emails or text files
    gpg --batch \
        --yes \
        --pinentry-mode loopback \
        --passphrase "$PASSPHRASE" \
        --symmetric \
        --armor \
        --cipher-algo AES256 \
        --output "$ASCII_FILE" \
        "$ORIGINAL_FILE"

    if test $status -eq 0
        echo "ASCII-armored encrypted file created: $ASCII_FILE"
        echo ""
        echo "First 5 lines of ASCII-armored output:"
        head -5 "$ASCII_FILE"
    else
        echo "ERROR: ASCII encryption failed."
        return 1
    end
end

function decrypt_file
    echo ""
    echo "--- DECRYPTION ---"
    # Decrypt using the same passphrase - batch and non-interactive
    gpg --batch \
        --yes \
        --pinentry-mode loopback \
        --passphrase "$PASSPHRASE" \
        --decrypt \
        --output "$DECRYPTED_FILE" \
        "$ENCRYPTED_FILE"

    if test $status -eq 0
        echo "Decrypted file: $DECRYPTED_FILE"
        echo ""
        echo "Decrypted content:"
        echo "---"
        cat "$DECRYPTED_FILE"
        echo "---"
    else
        echo "ERROR: Decryption failed."
        return 1
    end
end

function verify_integrity
    echo ""
    echo "--- INTEGRITY VERIFICATION ---"
    # Compare SHA256 hashes of original and decrypted files
    # Use Fish string split instead of awk (awk not installed in nixos/nix base)
    set orig_hash (string split ' ' (sha256sum "$ORIGINAL_FILE"))[1]
    set dec_hash  (string split ' ' (sha256sum "$DECRYPTED_FILE"))[1]

    echo "Original  SHA256: $orig_hash"
    echo "Decrypted SHA256: $dec_hash"

    if test "$orig_hash" = "$dec_hash"
        echo "INTEGRITY CHECK: PASSED - Files are identical."
    else
        echo "INTEGRITY CHECK: FAILED - Files differ!"
        return 1
    end
end

# --- Main execution ---
echo "=============================================="
echo " PRACTICAL CASE 2: SYMMETRIC ENCRYPTION (GPG)"
echo "=============================================="

create_sample_document
encrypt_symmetric
encrypt_symmetric_ascii
decrypt_file
verify_integrity

echo ""
echo "Symmetric encryption requires both parties to share the same passphrase."
echo "Key exchange problem: how to securely share the passphrase? See PC3 (asymmetric)."
echo "=============================================="