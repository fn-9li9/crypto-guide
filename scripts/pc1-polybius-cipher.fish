#!/usr/bin/env fish
# pc1-polybius-cipher.fish
# Practical Case 1: Polybius Square Cipher
# Extended version with explicit space encoding (00)

# --- Polybius square definition ---
# Grid layout (I and J share position 2,4):
#     1  2  3  4  5
# 1   A  B  C  D  E
# 2   F  G  H  IJ K
# 3   L  M  N  O  P
# 4   Q  R  S  T  U
# 5   V  W  X  Y  Z

set alphabet A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
# Row and column positions (1-indexed, J maps to same as I)
set positions \
    11 12 13 14 15 \
    21 22 23 24 24 \
    25 31 32 33 34 \
    35 41 42 43 44 \
    45 51 52 53 54 \
    55

# ----------------------------------------------------
# STANDARD ENCODE (keeps spaces as literal spaces)
# ----------------------------------------------------
function encode_polybius
    set -l input (string upper "$argv")
    set -l result ""

    for char in (string split "" "$input")
        if not string match -qr '[A-Z]' "$char"
            set result "$result$char"
            continue
        end

        for i in (seq 1 (count $alphabet))
            if test "$char" = "$alphabet[$i]"
                set result "$result$positions[$i] "
                break
            end
        end
    end

    echo (string trim "$result")
end

function decode_polybius
    set -l input "$argv"
    set -l result ""

    for code in (string split " " "$input")
        for i in (seq 1 (count $positions))
            if test "$code" = "$positions[$i]"
                set result "$result$alphabet[$i]"
                break
            end
        end
    end

    echo "$result"
end

# ----------------------------------------------------
# SPACE-AWARE VERSION (space = 00)
# ----------------------------------------------------
function encode_polybius_space
    set -l input (string upper "$argv")
    set -l result ""

    for char in (string split "" "$input")

        # If space → encode as 00
        if test "$char" = " "
            set result "$result""00 "
            continue
        end

        # Only encode letters
        if string match -qr '[A-Z]' "$char"
            for i in (seq 1 (count $alphabet))
                if test "$char" = "$alphabet[$i]"
                    set result "$result$positions[$i] "
                    break
                end
            end
        end
    end

    echo (string trim "$result")
end

function decode_polybius_space
    set -l input "$argv"
    set -l result ""

    for code in (string split " " "$input")

        # If 00 → space
        if test "$code" = "00"
            set result "$result "
            continue
        end

        for i in (seq 1 (count $positions))
            if test "$code" = "$positions[$i]"
                set result "$result$alphabet[$i]"
                break
            end
        end
    end

    echo "$result"
end

# ----------------------------------------------------
# --- Main demonstration ---
# ----------------------------------------------------

echo "=============================================="
echo " PRACTICAL CASE 1: POLYBIUS SQUARE CIPHER"
echo "=============================================="
echo ""
echo "Polybius Square (5x5 grid):"
echo "    1  2  3  4  5"
echo " 1  A  B  C  D  E"
echo " 2  F  G  H  IJ K"
echo " 3  L  M  N  O  P"
echo " 4  Q  R  S  T  U"
echo " 5  V  W  X  Y  Z"
echo ""

# Test message from the textbook
set plaintext "POLYBIOS CIPHER IS THE FIRST SUBSTITUTION CIPHER"

echo "Original message:"
echo $plaintext
echo ""

echo "---- Standard Encoding ----"
set encoded (encode_polybius "$plaintext")
echo "Encoded:"
echo $encoded
echo ""

echo "Decoded:"
echo (decode_polybius "$encoded")
echo ""

echo "---- Space-Aware Encoding (00 = space) ----"
set encoded_space (encode_polybius_space "$plaintext")
echo "Encoded with spaces:"
echo $encoded_space
echo ""

echo "Decoded with spaces:"
echo (decode_polybius_space "$encoded_space")
echo ""

echo "NOTE: J is treated as I (I/J share grid position 24)"
echo "=============================================="