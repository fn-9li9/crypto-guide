#!/usr/bin/env fish
# =============================================================================
# pc3-key-generation.fish
# Asymmetric RSA Key Pair Generation with GnuPG
# SRE Cryptography Guide - Practical Case 3
# =============================================================================
# Description:
#   Generates an RSA 4096-bit asymmetric key pair using GPG batch mode.
#   Reads parameters from keyparams.conf for reproducibility.
#   Lists keys after creation to confirm success.
# Prerequisites:
#   - gnupg installed
#   - keyparams.conf in the same directory (or pass path as argument)
# Usage:
#   fish pc3-key-generation.fish [keyparams.conf]
# =============================================================================

set KEYPARAMS_FILE $argv[1]
set GNUPG_HOME "$HOME/.gnupg"

# Default to keyparams.conf in same directory as script
if test -z "$KEYPARAMS_FILE"
    set SCRIPT_DIR (dirname (status filename))
    set KEYPARAMS_FILE "$SCRIPT_DIR/keyparams.conf"
end

echo "============================================================"
echo " PC3 - Asymmetric RSA 4096 Key Pair Generation"
echo " SRE Cryptography Automation Guide"
echo "============================================================"
echo ""

# ---------------------------------------------------------
# Step 1: Verify prerequisites
# ---------------------------------------------------------
echo "[STEP 1] Checking prerequisites..."

if not command -q gpg
    echo "[ERROR] gpg not found. Install with: nix-shell -p gnupg"
    exit 1
end

echo "[OK]    gpg version: "(gpg --version | head -1)

if not test -f "$KEYPARAMS_FILE"
    echo "[ERROR] keyparams.conf not found at: $KEYPARAMS_FILE"
    echo "[INFO]  Generate it with: fish pc3-key-generation.fish /path/to/keyparams.conf"
    echo "        Or run the README.md setup steps first."
    exit 1
end

echo "[OK]    Key parameters file: $KEYPARAMS_FILE"
echo ""

# ---------------------------------------------------------
# Step 2: Display key parameters (sanitized)
# ---------------------------------------------------------
echo "[STEP 2] Key parameters (from $KEYPARAMS_FILE):"
echo "---"
grep -v "^Passphrase" $KEYPARAMS_FILE
echo "---"
echo ""

# ---------------------------------------------------------
# Step 3: Ensure GPG home directory exists and is configured
# ---------------------------------------------------------
echo "[STEP 3] Configuring GPG home directory: $GNUPG_HOME"
mkdir -p "$GNUPG_HOME"
chmod 700 "$GNUPG_HOME"

# Ensure allow-loopback-pinentry is set
set AGENT_CONF "$GNUPG_HOME/gpg-agent.conf"
if not test -f "$AGENT_CONF"
    echo "allow-loopback-pinentry" > "$AGENT_CONF"
    echo "[OK]    Created $AGENT_CONF with loopback pinentry."
else if not grep -q "allow-loopback-pinentry" "$AGENT_CONF"
    echo "allow-loopback-pinentry" >> "$AGENT_CONF"
    echo "[OK]    Added allow-loopback-pinentry to $AGENT_CONF"
else
    echo "[OK]    $AGENT_CONF already configured."
end

# Kill and restart agent to apply changes
gpgconf --kill gpg-agent
echo "[OK]    GPG agent restarted."
echo ""

# ---------------------------------------------------------
# Step 4: Generate the key pair
# ---------------------------------------------------------
echo "[STEP 4] Generating RSA 4096 key pair (batch mode, non-interactive)..."
echo "[INFO]  This may take a moment to gather entropy..."

gpg \
    --batch \
    --yes \
    --pinentry-mode loopback \
    --gen-key "$KEYPARAMS_FILE"

set GEN_STATUS $status
echo ""

if test $GEN_STATUS -eq 0
    echo "[OK]    Key pair generated successfully."
else
    echo "[ERROR] Key generation failed (exit code: $GEN_STATUS)."
    echo "[INFO]  Common causes:"
    echo "        - Key with same UID already exists (delete first)"
    echo "        - Insufficient entropy"
    echo "        - Malformed keyparams.conf"
    exit 1
end

echo ""

# ---------------------------------------------------------
# Step 5: List all keys to confirm
# ---------------------------------------------------------
echo "[STEP 5] Listing all keys in keyring:"
echo ""
gpg --list-keys --keyid-format LONG
echo ""

# ---------------------------------------------------------
# Step 6: Export public key for sharing
# ---------------------------------------------------------
echo "[STEP 6] Extracting UID from keyparams.conf..."
set NAME_REAL (grep "^Name-Real:" "$KEYPARAMS_FILE" | awk -F': ' '{print $2}')
set EXPORT_FILE "/tmp/$(string replace -a ' ' '_' $NAME_REAL)_public.gpg"

gpg \
    --batch \
    --yes \
    --armor \
    --output "$EXPORT_FILE" \
    --export "$NAME_REAL"

if test $status -eq 0
    echo "[OK]    Public key exported to: $EXPORT_FILE"
    echo ""
    echo "[INFO]  Public key content:"
    echo "---"
    cat "$EXPORT_FILE"
    echo "---"
else
    echo "[WARN]  Public key export failed."
end

echo ""
echo "[SUMMARY]"
echo "  Key type    : RSA 4096-bit"
echo "  Key owner   : $NAME_REAL"
echo "  Params file : $KEYPARAMS_FILE"
echo "  Public key  : $EXPORT_FILE"
echo ""
echo "[NOTE] The private key is stored encrypted in: $GNUPG_HOME/private-keys-v1.d/"
echo "       Back up this directory securely and offline."
echo "       Never share the private key."
echo "============================================================"