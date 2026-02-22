#!/usr/bin/env fish
# =============================================================================
# pc5-key-exchange.fish
# GPG Public Key Export and Import (Key Exchange)
# SRE Cryptography Guide - Practical Case 5
# =============================================================================
# Description:
#   Automates the process of exporting a public key and importing
#   a recipient's public key into the local keyring.
#   Simulates the Fernando-Macarena key exchange from the textbook.
#   Demonstrates key verification via fingerprint.
# Prerequisites:
#   - gnupg installed
#   - At least one GPG key generated (run pc3-key-generation.fish first)
# Usage:
#   fish pc5-key-exchange.fish export [key_identifier] [output_file]
#   fish pc5-key-exchange.fish import [key_file]
#   fish pc5-key-exchange.fish demo
# =============================================================================

set MODE $argv[1]
set KEY_ARG $argv[2]
set FILE_ARG $argv[3]

set EXCHANGE_DIR "/tmp/pc5-key-exchange"
mkdir -p "$EXCHANGE_DIR"

echo "============================================================"
echo " PC5 - GPG Public Key Exchange"
echo " SRE Cryptography Automation Guide"
echo "============================================================"
echo ""

# ---------------------------------------------------------
# Function: export_key
# Exports a public key to an armored ASCII file
# ---------------------------------------------------------
function export_key
    set key_id $argv[1]
    set output_file $argv[2]

    if test -z "$key_id"
        echo "[ERROR] Key identifier required."
        return 1
    end

    if test -z "$output_file"
        set safe_name (string replace -a ' ' '_' "$key_id")
        set output_file "$EXCHANGE_DIR/$safe_name.gpg"
    end

    echo "[EXPORT] Exporting public key for: $key_id"
    echo "[INFO]   Output file: $output_file"

    gpg \
        --batch \
        --yes \
        --armor \
        --output "$output_file" \
        --export "$key_id"

    if test $status -eq 0
        echo "[OK]    Public key exported successfully."
        echo ""
        echo "[INFO]  Exported key content:"
        echo "---"
        cat "$output_file"
        echo "---"
        echo ""
        echo "[INFO]  Key fingerprint:"
        gpg --with-fingerprint --import-options show-only --import "$output_file" 2>/dev/null
    else
        echo "[ERROR] Export failed for key: $key_id"
        return 1
    end
end

# ---------------------------------------------------------
# Function: import_key
# Imports a public key from a file into the keyring
# ---------------------------------------------------------
function import_key
    set key_file $argv[1]

    if not test -f "$key_file"
        echo "[ERROR] Key file not found: $key_file"
        return 1
    end

    echo "[IMPORT] Importing public key from: $key_file"

    # Show what will be imported
    echo "[INFO]  Key to be imported:"
    gpg --with-fingerprint --import-options show-only --import "$key_file" 2>/dev/null
    echo ""

    gpg \
        --batch \
        --yes \
        --import "$key_file"

    if test $status -eq 0
        echo "[OK]    Key imported successfully into keyring."
        echo ""
        echo "[INFO]  Updated keyring:"
        gpg --list-keys --keyid-format LONG
    else
        echo "[ERROR] Import failed for file: $key_file"
        return 1
    end
end

# ---------------------------------------------------------
# Function: verify_fingerprint
# Shows fingerprint of all keys for manual verification
# ---------------------------------------------------------
function verify_fingerprint
    echo "[VERIFY] Key fingerprints for verification:"
    echo ""
    gpg --fingerprint
end

# ---------------------------------------------------------
# Function: demo_exchange
# Simulates the Fernando-Macarena key exchange from textbook
# ---------------------------------------------------------
function demo_exchange
    echo "[DEMO] Simulating textbook key exchange (Fernando <-> Macarena)"
    echo ""

    # List current keys
    echo "[INFO]  Current keyring contents:"
    gpg --list-keys 2>/dev/null
    echo ""

    # Get the first available key for demo
    set first_uid (gpg --list-keys --with-colons 2>/dev/null | grep "^uid" | head -1 | awk -F: '{print $10}')

    if test -z "$first_uid"
        echo "[WARN]  No keys available in keyring."
        echo "[INFO]  Run pc3-key-generation.fish first to create a key."
        return 1
    end

    set first_name (echo $first_uid | awk '{print $1}')
    echo "[INFO]  Exporting key for: $first_uid"

    set export_file "$EXCHANGE_DIR/$(string replace -a ' ' '_' $first_name)_public.gpg"

    gpg \
        --batch \
        --yes \
        --armor \
        --output "$export_file" \
        --export "$first_uid"

    if test $status -eq 0
        echo "[OK]    Public key exported: $export_file"
        echo ""
        echo "[SCENARIO]"
        echo "  1. Fernando exports his public key (this step)"
        echo "  2. Fernando sends $export_file to Macarena via email/USB/server"
        echo "  3. Macarena imports the file: gpg --import $export_file"
        echo "  4. Macarena can now encrypt messages for Fernando"
        echo "  5. Only Fernando can decrypt them (using his private key)"
        echo ""
        echo "[NOTE] In production, verify fingerprints out-of-band before trusting."
        echo "       Use key signing parties or a trusted CA for high-security environments."
    else
        echo "[ERROR] Demo export failed."
        return 1
    end

    echo ""
    echo "[VERIFY] Current keyring with fingerprints:"
    gpg --fingerprint
end

# =============================================================================
# Main dispatch
# =============================================================================
switch $MODE
    case "export"
        export_key "$KEY_ARG" "$FILE_ARG"

    case "import"
        import_key "$KEY_ARG"

    case "verify"
        verify_fingerprint

    case "demo" ""
        demo_exchange

    case '*'
        echo "[ERROR] Unknown mode: $MODE"
        echo "Usage:"
        echo "  fish pc5-key-exchange.fish export [key_id] [output_file]"
        echo "  fish pc5-key-exchange.fish import [key_file]"
        echo "  fish pc5-key-exchange.fish verify"
        echo "  fish pc5-key-exchange.fish demo"
        exit 1
end

echo ""
echo "============================================================"