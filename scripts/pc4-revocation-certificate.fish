#!/usr/bin/env fish
# pc4-revocation-certificate.fish
# Practical Case 4: Revocation Certificate Generation
# A revocation certificate should be created immediately after generating a key pair.
# If the private key is compromised or lost, publishing this certificate notifies
# all other users that the public key must no longer be trusted for encryption.

set PASSPHRASE "CryptoLab2024!"
set REVOCATION_DIR "/workspace/samples/revocation"
set REVOCATION_FILE "$REVOCATION_DIR/revocation_cert.asc"

function ensure_key_exists
    echo "--- Checking for key to revoke ---"
    set key_id (gpg --batch --list-keys --with-colons 2>/dev/null | grep "^pub" | head -1 | cut -d: -f5)

    if test -z "$key_id"
        echo "No key found. Run pc3-key-generation.fish first."
        return 1
    end

    echo "Key found: $key_id"
    echo "$key_id"
end

function generate_revocation_certificate
    set -l key_email "cryptolab@sre-lab.local"

    echo ""
    echo "--- Generating Revocation Certificate ---"
    echo "Target key: $key_email"
    echo "Reason: Certificate created immediately after key generation (precautionary)"
    echo ""

    mkdir -p "$REVOCATION_DIR"

    # Generate revocation certificate non-interactively
    # Reason code 0 = No reason specified (used when creating precautionary cert)
    gpg --batch \
        --yes \
        --pinentry-mode loopback \
        --passphrase "$PASSPHRASE" \
        --output "$REVOCATION_FILE" \
        --gen-revoke "$key_email" << 'EOF'
y
0
Revocation certificate created immediately after key generation. This key may be compromised or no longer in use.

y
EOF

    if test $status -eq 0
        echo "Revocation certificate saved to: $REVOCATION_FILE"
    else
        echo "Attempting alternative generation method..."
        # Some GPG versions handle this differently
        echo "y
0
Precautionary revocation certificate.

y" | gpg --batch \
            --yes \
            --pinentry-mode loopback \
            --passphrase "$PASSPHRASE" \
            --command-fd 0 \
            --output "$REVOCATION_FILE" \
            --gen-revoke "$key_email" 2>/dev/null

        if test $status -eq 0
            echo "Revocation certificate saved to: $REVOCATION_FILE"
        else
            echo "NOTE: Interactive revocation may be needed on some GPG versions."
            echo "Command: gpg --gen-revoke cryptolab@sre-lab.local > $REVOCATION_FILE"
        end
    end
end

function display_revocation_cert
    if test -f "$REVOCATION_FILE"
        echo ""
        echo "--- Revocation Certificate Content (first 10 lines) ---"
        head -10 "$REVOCATION_FILE"
        echo "..."
        echo ""
        echo "Full path: $REVOCATION_FILE"
        echo "File size: "(wc -c < "$REVOCATION_FILE")" bytes"
    end
end

function show_revocation_warning
    echo ""
    echo "=== IMPORTANT SECURITY WARNINGS ==="
    echo ""
    echo "1. Store this certificate in a SECURE OFFLINE location (encrypted USB, paper safe)."
    echo "2. Anyone who obtains this certificate can INVALIDATE your key."
    echo "3. To revoke a key, import the certificate and publish to a keyserver:"
    echo "   gpg --import $REVOCATION_FILE"
    echo "   gpg --keyserver hkps://keys.openpgp.org --send-keys KEY_ID"
    echo ""
    echo "4. A revoked public key can still VERIFY old signatures, but cannot encrypt."
    echo "5. Revocation reason codes:"
    echo "   0 = No reason specified"
    echo "   1 = Key has been compromised"
    echo "   2 = Key is superseded"
    echo "   3 = Key is no longer used"
    echo "==================================="
end

function show_revocation_reasons
    echo ""
    echo "--- Revocation Reason Codes (from textbook) ---"
    printf "%-5s %-35s\n" "Code" "Reason"
    printf "%-5s %-35s\n" "----" "------"
    printf "%-5s %-35s\n" "0"    "No reason specified"
    printf "%-5s %-35s\n" "1"    "Key has been compromised"
    printf "%-5s %-35s\n" "2"    "Key superseded by new key"
    printf "%-5s %-35s\n" "3"    "Key no longer used"
end

# --- Main execution ---
echo "=============================================="
echo " PRACTICAL CASE 4: REVOCATION CERTIFICATE"
echo "=============================================="
echo ""
echo "Best practice: Create a revocation certificate IMMEDIATELY after key generation."
echo "This allows invalidation of the public key if the private key is lost or compromised."
echo ""

ensure_key_exists
and begin
    generate_revocation_certificate
    display_revocation_cert
    show_revocation_reasons
    show_revocation_warning
end

echo "=============================================="