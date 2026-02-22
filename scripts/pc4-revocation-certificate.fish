#!/usr/bin/env fish
# pc4-revocation-certificate.fish
# Practical Case 4: Revocation Certificate Generation

set PASSPHRASE "fn-stella-sre"
set REVOCATION_DIR "/workspace/samples/revocation"
set REVOCATION_FILE "$REVOCATION_DIR/revocation_cert.asc"

function get_primary_fingerprint
    # Use Python to parse --with-colons output (no awk dependency)
    python3 -c "
import subprocess
out = subprocess.check_output(
    ['gpg','--batch','--list-keys','--with-colons'],
    stderr=subprocess.DEVNULL
).decode()
fpr = None
after_pub = False
for line in out.splitlines():
    if line.startswith('pub:'):
        after_pub = True
    elif line.startswith('fpr:') and after_pub:
        fpr = line.split(':')[9]
        after_pub = False
if fpr:
    print(fpr)
"
end

function ensure_key_exists
    echo "--- Checking for key to revoke ---"
    set fpr (get_primary_fingerprint)
    if test -z "$fpr"
        echo "No key found. Run pc3-key-generation.fish first."
        return 1
    end
    echo "Primary key fingerprint: $fpr"
end

function generate_revocation_certificate
    set -l fpr (get_primary_fingerprint)

    echo ""
    echo "--- Generating Revocation Certificate ---"
    echo "Target fingerprint: $fpr"
    echo "Reason: Precautionary certificate (code 0 - unspecified)"
    echo ""

    mkdir -p "$REVOCATION_DIR"

    # Write the expect script via Python to avoid Fish/heredoc quoting issues
    set tmpexp (mktemp /tmp/revoke_XXXXXX.exp)

    python3 -c "
import sys
fpr  = sys.argv[1]
pwd  = sys.argv[2]
out  = sys.argv[3]
script = '''#!/usr/bin/env expect
set timeout 30
spawn gpg --yes --pinentry-mode loopback --passphrase {PWD} --output {OUT} --gen-revoke {FPR}
expect {
    -re {[Cc]reate a revocation} { send \"y\\r\"; exp_continue }
    -re {Your decision}          { send \"0\\r\"; exp_continue }
    -re {Enter an optional}      { send \"Precautionary revocation certificate.\\r\"; exp_continue }
    -re {empty line}             { send \"\\r\"; exp_continue }
    -re {[Ii]s this okay}        { send \"y\\r\"; exp_continue }
    -re {[Pp]assphrase}          { send \"{PWD}\\r\"; exp_continue }
    eof {}
}
'''.replace('{FPR}', fpr).replace('{PWD}', pwd).replace('{OUT}', out)
with open(sys.argv[4], 'w') as f:
    f.write(script)
" "$fpr" "$PASSPHRASE" "$REVOCATION_FILE" "$tmpexp"

    expect "$tmpexp" > /dev/null 2>&1
    set result $status
    rm -f "$tmpexp"

    if test $result -eq 0; and test -s "$REVOCATION_FILE"
        echo "Revocation certificate saved to: $REVOCATION_FILE"
    else
        echo "ERROR: Could not generate revocation certificate."
        echo "Run manually: gpg --gen-revoke $fpr"
        return 1
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
