#!/usr/bin/env fish
# =============================================================================
# pc4-revocation-certificate.fish
# GPG Revocation Certificate Generation
# SRE Cryptography Guide - Practical Case 4
# =============================================================================
# Description:
#   Generates a revocation certificate for a GPG key immediately after
#   key creation. This is an SRE best practice: revocation certificates
#   must be generated and stored offline before they are needed.
#   Uses batch mode and loopback pinentry for full automation.
# Prerequisites:
#   - gnupg installed
#   - An existing GPG key (run pc3-key-generation.fish first)
# Usage:
#   fish pc4-revocation-certificate.fish [key_identifier] [passphrase]
# =============================================================================

set KEY_ID $argv[1]
set PASSPHRASE $argv[2]
set REVOC_DIR "/tmp/revocation-certs"

echo "============================================================"
echo " PC4 - GPG Revocation Certificate Generation"
echo " SRE Cryptography Automation Guide"
echo "============================================================"
echo ""

# ---------------------------------------------------------
# Step 1: List available keys
# ---------------------------------------------------------
echo "[STEP 1] Listing available GPG keys..."
echo ""
gpg --list-keys --keyid-format LONG
echo ""

# ---------------------------------------------------------
# Step 2: Resolve key identifier
# ---------------------------------------------------------
if test -z "$KEY_ID"
    echo "[INFO]  No key identifier provided. Attempting to use first available key."
    set KEY_ID (gpg --list-keys --with-colons 2>/dev/null | grep "^uid" | head -1 | awk -F: '{print $10}' | awk '{print $1}')
    if test -z "$KEY_ID"
        # Try getting fingerprint instead
        set KEY_ID (gpg --list-keys --with-colons 2>/dev/null | grep "^pub" | head -1 | awk -F: '{print $5}')
    end
    if test -z "$KEY_ID"
        echo "[ERROR] No keys found. Run pc3-key-generation.fish first."
        exit 1
    end
    echo "[INFO]  Using key: $KEY_ID"
else
    echo "[INFO]  Using provided key identifier: $KEY_ID"
end

echo ""

# ---------------------------------------------------------
# Step 3: Create output directory
# ---------------------------------------------------------
echo "[STEP 2] Creating secure output directory: $REVOC_DIR"
mkdir -p "$REVOC_DIR"
chmod 700 "$REVOC_DIR"
echo "[OK]    Directory created with permissions 700."
echo ""

# ---------------------------------------------------------
# Step 4: Generate revocation certificate (batch mode)
# ---------------------------------------------------------
set REVOC_FILE "$REVOC_DIR/revocation_cert_$(string replace -a ':' '' $KEY_ID).asc"
set REVOC_REASON "0"  # 0 = No reason specified (created preventively)
set REVOC_COMMENT "This certificate was created immediately after key generation as a preventive measure. The key may be compromised or is no longer in use."

echo "[STEP 3] Generating revocation certificate..."
echo "[INFO]   Key       : $KEY_ID"
echo "[INFO]   Reason    : $REVOC_REASON (No reason specified / preventive)"
echo "[INFO]   Output    : $REVOC_FILE"
echo ""

# Build the batch input for gen-revoke
# Format: y\nREASON\nCOMMENT\n\ny\n
set BATCH_INPUT "y\n$REVOC_REASON\n$REVOC_COMMENT\n\ny\n"

if test -n "$PASSPHRASE"
    # With passphrase via loopback
    printf $BATCH_INPUT | gpg \
        --batch \
        --yes \
        --pinentry-mode loopback \
        --passphrase "$PASSPHRASE" \
        --command-fd 0 \
        --status-fd 2 \
        --output "$REVOC_FILE" \
        --gen-revoke "$KEY_ID" 2>/dev/null
else
    # Without passphrase (unprotected key)
    printf $BATCH_INPUT | gpg \
        --batch \
        --yes \
        --command-fd 0 \
        --status-fd 2 \
        --output "$REVOC_FILE" \
        --gen-revoke "$KEY_ID" 2>/dev/null
end

set GEN_STATUS $status

# GPG gen-revoke may exit non-zero even on success; check file existence
if test -f "$REVOC_FILE" -a -s "$REVOC_FILE"
    echo "[OK]    Revocation certificate created: $REVOC_FILE"
    chmod 400 "$REVOC_FILE"  # Read-only for owner only
    echo "[OK]    Permissions set to 400 (read-only, owner only)."
    echo ""
    echo "[INFO]  Revocation certificate content:"
    echo "---"
    cat "$REVOC_FILE"
    echo "---"
else
    echo "[ERROR] Revocation certificate creation failed."
    echo "[INFO]  Exit code: $GEN_STATUS"
    echo "[INFO]  Try running: gpg --gen-revoke $KEY_ID"
    echo "        and follow the interactive prompts."
    exit 1
end

echo ""

# ---------------------------------------------------------
# Step 5: Export to multiple secure locations (SRE practice)
# ---------------------------------------------------------
echo "[STEP 4] Copying revocation certificate to backup location..."

set BACKUP_FILE "$HOME/revocation_backup_$(date +%Y%m%d).asc"
cp "$REVOC_FILE" "$BACKUP_FILE"
chmod 400 "$BACKUP_FILE"

echo "[OK]    Backup saved: $BACKUP_FILE"
echo ""

# ---------------------------------------------------------
# Summary and SRE guidance
# ---------------------------------------------------------
echo "[SUMMARY]"
echo "  Key          : $KEY_ID"
echo "  Revoc cert   : $REVOC_FILE"
echo "  Backup       : $BACKUP_FILE"
echo "  Permissions  : 400 (read-only, owner only)"
echo ""
echo "[SRE WARNING]"
echo "  Store this certificate in the following secure locations:"
echo "  1. Encrypted offline USB drive (physically secured)"
echo "  2. Organizational key management system"
echo "  3. Printed paper copy in a locked safe (if required by policy)"
echo ""
echo "  To REVOKE the key (when needed):"
echo "  gpg --import $REVOC_FILE"
echo "  gpg --keyserver hkps://keys.openpgp.org --send-keys $KEY_ID"
echo ""
echo "  NEVER leave this certificate unprotected on a shared system."
echo "============================================================"