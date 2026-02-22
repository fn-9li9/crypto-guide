#!/usr/bin/env fish
# pc5-key-exchange.fish
# Practical Case 5: Key Exchange Using GPG
# Demonstrates the asymmetric key exchange workflow:
# - Export a public key
# - Import another user's public key into the keyring
# - Encrypt a message for another user using their public key
# - Decrypt a message using your own private key

set PASSPHRASE "fn-stella-sre"
set SAMPLES_DIR "/workspace/samples"
set KEYRING_DIR "/workspace/samples/keyring-demo"

function simulate_user_alice
    echo "--- Simulating: Alice exports her public key ---"
    # In a real scenario, Alice would run this on her own machine
    # Alice's key is our lab key; we simulate a second user for the exchange

    # Capture stdout directly to file (more reliable than --output in some GPG builds)
    gpg --batch --armor --export "stella.sre.inc@gmail.com" > "$KEYRING_DIR/alice_public.asc" 2>/dev/null

    if test -s "$KEYRING_DIR/alice_public.asc"
        echo "Alice's public key exported to: $KEYRING_DIR/alice_public.asc"
        echo ""
        echo "First 4 lines of exported public key:"
        head -4 "$KEYRING_DIR/alice_public.asc"
        echo "..."
        echo ""
        echo "This file is safe to share publicly."
    else
        echo "ERROR: Could not export public key. Ensure PC3 was completed first."
        return 1
    end
end

function simulate_key_import
    echo ""
    echo "--- Simulating: Bob imports Alice's public key ---"
    # In a real scenario, Bob would receive alice_public.asc via email,
    # keyserver, or any other channel (even insecure ones - public key is safe)

    gpg --batch \
        --import "$KEYRING_DIR/alice_public.asc" 2>&1

    echo ""
    echo "Keys in keyring after import:"
    gpg --batch --list-keys
end

function encrypt_for_recipient
    echo ""
    echo "--- Bob encrypts a message for Alice using her PUBLIC key ---"
    # Only Alice can decrypt this message because only she has the private key
    # This solves the key distribution problem of symmetric cryptography

    set message_file "$KEYRING_DIR/message_for_alice.txt"
    set encrypted_file "$KEYRING_DIR/message_for_alice_encrypted.asc"

    # Create a message from Bob to Alice
    echo "From: Bob" > "$message_file"
    echo "To: Alice" >> "$message_file"
    echo "Subject: Encrypted message using asymmetric cryptography" >> "$message_file"
    echo "" >> "$message_file"
    echo "This message was encrypted with your PUBLIC key." >> "$message_file"
    echo "Only you can decrypt it with your PRIVATE key." >> "$message_file"
    echo "No shared secret was needed for this encryption." >> "$message_file"
    echo "Date: "(date) >> "$message_file"

    echo "Original message:"
    cat "$message_file"
    echo ""

    # Encrypt using Alice's public key - recipient cannot be decrypted by Bob
    gpg --batch \
        --yes \
        --armor \
        --encrypt \
        --recipient "stella.sre.inc@gmail.com" \
        --output "$encrypted_file" \
        "$message_file" 2>/dev/null

    if test $status -eq 0
        echo "Encrypted file: $encrypted_file"
        echo ""
        echo "Encrypted content (first 8 lines):"
        head -8 "$encrypted_file"
        echo "..."
    else
        echo "NOTE: Encryption to untrusted key requires --trust-model always"
        gpg --batch \
            --yes \
            --armor \
            --trust-model always \
            --encrypt \
            --recipient "stella.sre.inc@gmail.com" \
            --output "$encrypted_file" \
            "$message_file" 2>/dev/null
        if test $status -eq 0
            echo "Encrypted file created with --trust-model always: $encrypted_file"
        end
    end
end

function decrypt_message
    echo ""
    echo "--- Alice decrypts the message using her PRIVATE key ---"

    set encrypted_file "$KEYRING_DIR/message_for_alice_encrypted.asc"
    set decrypted_file "$KEYRING_DIR/message_decrypted.txt"

    if not test -f "$encrypted_file"
        echo "No encrypted file found. Skipping decryption."
        return 0
    end

    gpg --batch \
        --yes \
        --pinentry-mode loopback \
        --passphrase "$PASSPHRASE" \
        --decrypt \
        --output "$decrypted_file" \
        "$encrypted_file" 2>/dev/null

    if test $status -eq 0
        echo "Decrypted message:"
        echo "---"
        cat "$decrypted_file"
        echo "---"
    else
        echo "Decryption requires the matching private key and correct passphrase."
    end
end

function show_key_exchange_summary
    echo ""
    echo "=== KEY EXCHANGE SUMMARY ==="
    echo ""
    echo "Symmetric problem:  n users need n*(n-1)/2 shared secrets"
    echo "  5 users  = 10 keys needed"
    echo "  10 users = 45 keys needed"
    echo "  100 users= 4950 keys needed"
    echo ""
    echo "Asymmetric solution: each user has 1 key pair (public + private)"
    echo "  Any number of users: each needs only 1 private key"
    echo "  Public keys are shared openly - no secure channel needed"
    echo ""
    echo "Public key servers for key distribution:"
    echo "  hkps://keys.openpgp.org"
    echo "  hkps://keyserver.ubuntu.com"
    echo "  hkps://pgp.mit.edu"
    echo "=========================="
end

# --- Main execution ---
echo "=============================================="
echo " PRACTICAL CASE 5: KEY EXCHANGE USING GPG"
echo "=============================================="
echo ""
echo "Goal: Demonstrate how asymmetric cryptography solves the"
echo "      key distribution problem inherent in symmetric cryptography."
echo ""

mkdir -p "$KEYRING_DIR"

simulate_user_alice
and begin
    simulate_key_import
    encrypt_for_recipient
    decrypt_message
    show_key_exchange_summary
end
