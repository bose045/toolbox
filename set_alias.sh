#!/bin/bash

# Use TOOLBOXDIR if defined, otherwise fall back to location of this script
if [ -z "$TOOLBOXDIR" ]; then
    TOOLBOXDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
    echo "🔔 TOOLBOXDIR not set. Using local path: $TOOLBOXDIR"
fi

ALIAS_FILE="$TOOLBOXDIR/alias_def.txt"

echo "🔧 Adding a new alias to $ALIAS_FILE"

# Ask for alias name
read -p "Enter alias name (e.g., gitpush): " alias_name

# Enable tab completion for script path
echo "Enter relative script path from toolbox root ($TOOLBOXDIR):"
cd "$TOOLBOXDIR" || exit 1
read -e -p "> " relative_path

# Expand to full path for validation
full_script_path="$TOOLBOXDIR/$relative_path"

# Check if the file exists
if [ ! -f "$full_script_path" ]; then
    echo "❌ Error: $full_script_path does not exist."
    exit 1
fi

# Build alias line
alias_line="alias $alias_name=\"\$TOOLBOXDIR/$relative_path\""

# Avoid duplicates
if grep -q "^alias $alias_name=" "$ALIAS_FILE"; then
    echo "⚠️  Alias '$alias_name' already exists in $ALIAS_FILE. Not adding."
else
    echo "$alias_line" >> "$ALIAS_FILE"
    echo "✅ Alias added: $alias_line"
fi

