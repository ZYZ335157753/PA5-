#!/bin/bash

# ==============================================================================
# Script Name: setup_env.sh
# Description: Automates the linking of necessary COOL compiler components
#              (lexer, parser, semant) for the PA5 environment on Ubuntu.
# Usage: ./setup_env.sh
# ==============================================================================

# Default paths (Standard CS143 environment)
BIN_DIR="/usr/class/bin"

# Check if user provided a custom bin directory
if [ "$1" != "" ]; then
    BIN_DIR="$1"
fi

echo "Setting up PA5 environment..."
echo "Looking for binaries in: $BIN_DIR"

# List of required components
COMPONENTS=("lexer" "parser" "semant")

for comp in "${COMPONENTS[@]}"; do
    TARGET="${BIN_DIR}/${comp}"
    
    if [ -f "$TARGET" ]; then
        echo "Linking $comp..."
        rm -f "$comp"  # Remove existing link/file
        ln -sf "$TARGET" .
    else
        echo "WARNING: $TARGET not found!"
        echo "  If you are not on the standard VM, please provide the path to the bin directory:"
        echo "  Usage: ./setup_env.sh /path/to/cool/bin"
    fi
done

echo "Checking for 'cgen'..."
if [ ! -f "cgen.cc" ]; then
    echo "WARNING: cgen.cc not found in current directory. Are you in the PA5 folder?"
fi

echo "Setup complete. Run 'make cgen' to compile."
