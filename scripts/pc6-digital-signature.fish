#!/usr/bin/env fish
# pc6-digital-signature.fish
# Practical Case 6: Digital Signature of a Document
# A digital signature ensures:
#   1. AUTHENTICITY  - the document was signed by the expected party
#   2. INTEGRITY     - the document has not been modified since signing
#   3. NON-REPUDIATION - the signer cannot deny having signed it
#
# Process:
#   1. Compute SHA hash of the document
#   2. Encrypt the hash with the PRIVATE key -> this is the digital signature
#   3. Verification: decrypt signature with PUBLIC key -> compare hashes

set PASSPHRASE "CryptoLab2024!"
set SAMPLES_DIR "/workspace/samples/signatures"
set DOCUMENT "$SAMPLES_DIR/contract.txt"

function create_document_to_sign
    echo "--- Creating document to sign ---"
    mkdir -p "$SAMPLES_DIR"

    echo "SERVICE AGREEMENT" > "$DOCUMENT"
    echo "==================" >> "$DOCUMENT"
    echo "" >> "$DOCUMENT"
    echo "Between: SRE Cryptography Laboratory (Party A)" >> "$DOCUMENT"
    echo "And:     Client Organization (Party B)" >> "$DOCUMENT"
    echo "" >> "$DOCUMENT"
    echo "Terms:" >> "$DOCUMENT"
    echo "1. Party A shall provide cryptographic automation services." >> "$DOCUMENT"
    echo "2. Confidentiality of all shared keys is mandatory." >> "$DOCUMENT"
    echo "3. This agreement is valid for one year from signing date." >> "$DOCUMENT"
    echo "" >> "$DOCUMENT"
    echo "Date: "(date) >> "$DOCUMENT"
    echo "" >> "$DOCUMENT"
    echo "Document created: $DOCUMENT"
end

function sign_clearsign
    echo ""
    echo "--- Option 1: Clear-sign (--clearsign) ---"
    echo "The original document content remains readable."
    echo "The signature is appended below the content."
    echo "Useful for: email, text files that humans must read."
    echo ""

    # Sign document - content visible, signature appended
    gpg --batch \
        --yes \
        --pinentry-mode loopback \
        --passphrase "$PASSPHRASE" \
        --clearsign \
        --output "$SAMPLES_DIR/contract_clearsigned.asc" \
        "$DOCUMENT"

    if test $status -eq 0
        echo "Clear-signed file: $SAMPLES_DIR/contract_clearsigned.asc"
        echo ""
        echo "Content of clear-signed document:"
        cat "$SAMPLES_DIR/contract_clearsigned.asc"
    else
        echo "ERROR: Clear-sign failed."
    end
end

function sign_detached
    echo ""
    echo "--- Option 2: Detached signature (-b) ---"
    echo "Signature stored in a SEPARATE file from the document."
    echo "Useful for: binary files, executables, release artifacts."
    echo ""

    # Create detached ASCII-armored signature
    gpg --batch \
        --yes \
        --pinentry-mode loopback \
        --passphrase "$PASSPHRASE" \
        --detach-sign \
        --armor \
        --output "$SAMPLES_DIR/contract.txt.sig" \
        "$DOCUMENT"

    if test $status -eq 0
        echo "Original document: $DOCUMENT"
        echo "Detached signature: $SAMPLES_DIR/contract.txt.sig"
        echo ""
        echo "Signature file content:"
        cat "$SAMPLES_DIR/contract.txt.sig"
    else
        echo "ERROR: Detached sign failed."
    end
end

function sign_binary
    echo ""
    echo "--- Option 3: Signed binary (-s) ---"
    echo "Document and signature merged into a single binary (compressed) file."
    echo "Useful for: archiving signed documents as a single unit."
    echo ""

    gpg --batch \
        --yes \
        --pinentry-mode loopback \
        --passphrase "$PASSPHRASE" \
        --sign \
        --armor \
        --output "$SAMPLES_DIR/contract_signed.gpg" \
        "$DOCUMENT"

    if test $status -eq 0
        echo "Signed file (armor): $SAMPLES_DIR/contract_signed.gpg"
        echo ""
        echo "First 6 lines:"
        head -6 "$SAMPLES_DIR/contract_signed.gpg"
        echo "..."
    else
        echo "ERROR: Binary sign failed."
    end
end

function verify_signatures
    echo ""
    echo "--- SIGNATURE VERIFICATION ---"
    echo "Verification uses the signer's PUBLIC key."
    echo "Anyone with the public key can verify - not just the original signer."
    echo ""

    # Verify clear-signed document
    if test -f "$SAMPLES_DIR/contract_clearsigned.asc"
        echo "Verifying clear-signed document..."
        gpg --batch --verify "$SAMPLES_DIR/contract_clearsigned.asc" 2>&1
        echo ""
    end

    # Verify detached signature
    if test -f "$SAMPLES_DIR/contract.txt.sig"
        echo "Verifying detached signature..."
        gpg --batch --verify "$SAMPLES_DIR/contract.txt.sig" "$DOCUMENT" 2>&1
        echo ""
    end
end

function demonstrate_tamper_detection
    echo ""
    echo "--- TAMPER DETECTION DEMONSTRATION ---"
    echo "Modifying a signed document invalidates the signature."
    echo ""

    set tampered "$SAMPLES_DIR/contract_tampered.asc"
    cp "$SAMPLES_DIR/contract_clearsigned.asc" "$tampered"

    # Modify the document content (simulating tampering)
    sed -i 's/one year/ten years/' "$tampered"

    echo "Document tampered: changed 'one year' to 'ten years'"
    echo "Attempting to verify tampered document..."
    gpg --batch --verify "$tampered" 2>&1
    echo ""
    echo "=> A BAD signature or verification failure confirms tampering was detected."
end

function show_hash_process
    echo ""
    echo "--- SHA-256 HASH OF DOCUMENT (hash function demonstration) ---"
    echo "The digital signature signs this hash value, not the full document."
    echo ""
    sha256sum "$DOCUMENT"
    echo ""
    echo "Any change to the document produces a completely different hash."
    echo "Example: modifying one character changes the entire hash."
end

# --- Main execution ---
echo "=============================================="
echo " PRACTICAL CASE 6: DIGITAL SIGNATURE"
echo "=============================================="
echo ""
echo "Digital signatures provide: Authenticity + Integrity + Non-repudiation"
echo "Process: hash(document) -> encrypt with PRIVATE key -> signature"
echo "Verify:  decrypt signature with PUBLIC key -> compare with hash(document)"
echo ""

create_document_to_sign
show_hash_process
sign_clearsign
sign_detached
sign_binary
verify_signatures
demonstrate_tamper_detection

echo ""
echo "Summary of signing options:"
echo "  --clearsign : human-readable content + signature appended"
echo "  --detach-sign (-b): separate signature file (for binaries)"
echo "  --sign (-s) : compressed binary blob (content + signature)"
echo "=============================================="