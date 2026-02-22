#!/usr/bin/env fish
# pc3-key-generation.fish
# Practical Case 3: Asymmetric Key Pair Generation with GnuPG
# Generates an RSA 4096-bit key pair using keyparams.conf for non-interactive operation
# Demonstrates Diffie-Hellman/asymmetric key concept (one public, one private key)

set KEYPARAMS "/workspace/keyparams.conf"
set GNUPGHOME "$GNUPGHOME"

function check_existing_keys
    echo "--- Checking existing keys in keyring ---"
    
    # Count existing public keys safely (fish-compatible)
    set key_count (gpg --batch --list-keys --with-colons 2>/dev/null | grep "^pub" | count)

    # Ensure numeric fallback
    if test -z "$key_count"
        set key_count 0
    end

    echo "Keys currently in keyring: $key_count"

    if test "$key_count" -gt 0
        gpg --batch --list-keys
    end
end

function generate_key_pair
    echo ""
    echo "--- Generating RSA 4096 key pair ---"
    echo "Using configuration: $KEYPARAMS"
    echo ""
    cat "$KEYPARAMS"
    echo ""
    echo "Generating key pair (this may take a moment)..."

    # Generate key non-interactively using batch file
    gpg --batch \
        --yes \
        --pinentry-mode loopback \
        --gen-key "$KEYPARAMS"

    if test $status -eq 0
        echo "Key pair generated successfully."
    else
        echo "ERROR: Key generation failed."
        return 1
    end
end

function list_keys
    echo ""
    echo "--- Public Key Listing ---"
    gpg --batch --list-keys

    echo ""
    echo "--- Secret Key Listing (private keys - never share!) ---"
    gpg --batch --list-secret-keys
end

function export_public_key
    echo ""
    echo "--- Exporting Public Key (ASCII-armored) ---"
    # The public key can be freely shared with anyone
    # It allows others to encrypt messages that only we can decrypt
    gpg --batch \
        --armor \
        --export "stella.sre.inc@gmail.com" \
        > /workspace/samples/cryptolab_public.asc 2>/dev/null

    if test $status -eq 0
        echo "Public key exported to: /workspace/samples/cryptolab_public.asc"
        echo ""
        echo "First 6 lines of public key:"
        head -6 /workspace/samples/cryptolab_public.asc
        echo "..."
    else
        echo "ERROR: Export failed. Ensure a key exists for stella.sre.inc@gmail.com"
    end
end

function show_key_fingerprint
    echo ""
    echo "--- Key Fingerprint ---"
    echo "Fingerprints are used to verify key authenticity out-of-band."
    gpg --batch --fingerprint "stella.sre.inc@gmail.com" 2>/dev/null
end

# --- Main execution ---
echo "=============================================="
echo " PRACTICAL CASE 3: ASYMMETRIC KEY PAIR GENERATION"
echo "=============================================="
echo ""
echo "Asymmetric cryptography (Diffie-Hellman, 1976):"
echo "  - Each entity has TWO keys: one public, one private"
echo "  - Public key: shared openly with everyone"
echo "  - Private key: never disclosed; must remain secret"
echo "  - Encrypt with recipient's PUBLIC key"
echo "  - Decrypt with your own PRIVATE key"
echo ""

mkdir -p /workspace/samples

check_existing_keys
generate_key_pair
list_keys
export_public_key
show_key_fingerprint

echo ""
echo "RSA 4096-bit key pair ready for use."
echo "Public key can be uploaded to a keyserver or shared directly."
echo "Private key is protected by the passphrase defined in keyparams.conf"
echo "=============================================="