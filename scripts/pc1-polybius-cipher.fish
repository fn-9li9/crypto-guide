#!/usr/bin/env fish
# pc1-polybius-cipher.fish
# Practical Case 1: Polybius Square Cipher
# Implements the substitution cipher developed by the Greek historian Polybius (~200 BC)
# Each letter is replaced by its row and column coordinates in a 5x5 grid

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

function encode_polybius
    set -l input (string upper "$argv")
    set -l result ""

    for char in (string split "" "$input")
        # Skip non-alphabetic characters
        if not string match -qr '[A-Z]' "$char"
            set result "$result$char"
            continue
        end

        # Find character index in alphabet
        set -l idx 0
        for i in (seq 1 (count $alphabet))
            if test "$char" = "$alphabet[$i]"
                set idx $i
                break
            end
        end

        if test $idx -gt 0
            set result "$result$positions[$idx] "
        end
    end

    echo (string trim "$result")
end

function decode_polybius
    set -l input "$argv"
    set -l result ""

    for code in (string split " " "$input")
        set -l found 0
        for i in (seq 1 (count $positions))
            if test "$code" = "$positions[$i]"
                set result "$result$alphabet[$i]"
                set found 1
                break
            end
        end
        if test $found -eq 0
            set result "$result$code"
        end
    end

    echo "$result"
end

# --- Main demonstration ---
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
echo "Original message: $plaintext"
echo ""

set encoded (encode_polybius "$plaintext")
echo "Encoded (Polybius): $encoded"
echo ""

set decoded (decode_polybius "$encoded")
echo "Decoded back: $decoded"
echo ""

# Second example using numeric pairs
echo "Example with short message: HELLO"
set msg "HELLO"
echo "Encoded: "(encode_polybius "$msg")
echo ""
echo "NOTE: J is treated as I (I/J share grid position 24)"
echo "=============================================="