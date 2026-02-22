#!/usr/bin/env fish
# =============================================================================
# pc1-polybius-cipher.fish
# Polybius Square Cipher - Encryption and Decryption
# SRE Cryptography Guide - Practical Case 1
# =============================================================================
# Description:
#   Implements the Polybius square cipher using a 5x5 grid (A-Z, I=J merged).
#   Encrypts plaintext to numeric pairs and decrypts numeric pairs back.
#   Demonstrates classical substitution cipher principles.
# Usage:
#   fish pc1-polybius-cipher.fish encrypt "YOUR MESSAGE HERE"
#   fish pc1-polybius-cipher.fish decrypt "11 12 13 ..."
# =============================================================================

# Polybius 5x5 grid (I and J share position 2,4)
# Rows and columns indexed 1-5
set GRID \
    "A" "B" "C" "D" "E" \
    "F" "G" "H" "I" "K" \
    "L" "M" "N" "O" "P" \
    "Q" "R" "S" "T" "U" \
    "V" "W" "X" "Y" "Z"

# ---------------------------------------------------------
# Function: get_coords
# Returns row and column (1-5) for a given letter
# ---------------------------------------------------------
function get_coords
    set letter (string upper $argv[1])
    # Treat J as I
    if test "$letter" = "J"
        set letter "I"
    end
    for row in 1 2 3 4 5
        for col in 1 2 3 4 5
            set idx (math "($row - 1) * 5 + $col")
            if test "$GRID[$idx]" = "$letter"
                echo "$row$col"
                return
            end
        end
    end
    echo "00"
end

# ---------------------------------------------------------
# Function: get_letter
# Returns letter at given row, column in the grid
# ---------------------------------------------------------
function get_letter
    set row $argv[1]
    set col $argv[2]
    set idx (math "($row - 1) * 5 + $col")
    echo $GRID[$idx]
end

# ---------------------------------------------------------
# Function: polybius_encrypt
# Encrypts a plaintext string using the Polybius square
# ---------------------------------------------------------
function polybius_encrypt
    set input (string upper "$argv")
    set result ""
    for i in (seq 1 (string length "$input"))
        set char (string sub -s $i -l 1 "$input")
        # Skip non-alpha characters (spaces become separator)
        if string match -qr '[A-Z]' "$char"
            set coords (get_coords "$char")
            if test -n "$result"
                set result "$result $coords"
            else
                set result "$coords"
            end
        else if test "$char" = " "
            set result "$result  "
        end
    end
    echo $result
end

# ---------------------------------------------------------
# Function: polybius_decrypt
# Decrypts a Polybius-encoded numeric string
# ---------------------------------------------------------
function polybius_decrypt
    set input "$argv"
    set result ""
    for token in (string split " " "$input")
        if test (string length "$token") -eq 2
            set row (string sub -s 1 -l 1 "$token")
            set col (string sub -s 2 -l 1 "$token")
            if test "$row" -ge 1 -a "$row" -le 5 -a "$col" -ge 1 -a "$col" -le 5
                set result "$result"(get_letter $row $col)
            end
        else if test -z "$token"
            set result "$result "
        end
    end
    echo $result
end

# ---------------------------------------------------------
# Function: print_grid
# Displays the Polybius square for reference
# ---------------------------------------------------------
function print_grid
    echo ""
    echo "Polybius Square (5x5):"
    echo "     1    2    3    4    5"
    echo "  +----+----+----+----+----+"
    for row in 1 2 3 4 5
        set line "  $row |"
        for col in 1 2 3 4 5
            set idx (math "($row - 1) * 5 + $col")
            set line "$line  $GRID[$idx]  |"
        end
        echo $line
        echo "  +----+----+----+----+----+"
    end
    echo ""
end

# =============================================================================
# Main execution
# =============================================================================
set mode $argv[1]
set message "$argv[2..-1]"

echo "============================================================"
echo " PC1 - Polybius Square Cipher"
echo " SRE Cryptography Automation Guide"
echo "============================================================"

print_grid

switch $mode
    case "encrypt"
        if test -z "$message"
            echo "[ERROR] No message provided for encryption."
            echo "Usage: fish pc1-polybius-cipher.fish encrypt \"YOUR MESSAGE\""
            exit 1
        end
        echo "[INPUT]     Plaintext  : $message"
        set encrypted (polybius_encrypt "$message")
        echo "[OUTPUT]    Ciphertext : $encrypted"
        echo ""
        echo "[INFO] Encryption complete. Each letter mapped to row/col pair."

    case "decrypt"
        if test -z "$message"
            echo "[ERROR] No ciphertext provided for decryption."
            echo "Usage: fish pc1-polybius-cipher.fish decrypt \"11 12 13 ...\""
            exit 1
        end
        echo "[INPUT]     Ciphertext : $message"
        set decrypted (polybius_decrypt "$message")
        echo "[OUTPUT]    Plaintext  : $decrypted"
        echo ""
        echo "[INFO] Decryption complete."

    case '*'
        # Default demo: encrypt and then decrypt the canonical example
        set demo_message "el cifrador de Polybios es el primer cifrador por sustitucion de caracteres"
        echo "[DEMO] Running built-in example from the textbook."
        echo ""
        echo "[INPUT]     Plaintext  : $demo_message"
        set encrypted (polybius_encrypt "$demo_message")
        echo "[ENCRYPT]   Ciphertext : $encrypted"
        set decrypted (polybius_decrypt "$encrypted")
        echo "[DECRYPT]   Recovered  : $decrypted"
        echo ""
        echo "[INFO] Demo complete. I=J share position 2,4 in this grid."
end

echo "============================================================"