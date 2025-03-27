#!/bin/bash

echo "🔧 Installing toolbox from current directory..."

# Get the absolute path to the current script's directory
TOOLBOX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Target .bashrc
BASHRC="$HOME/.bashrc"

# Make all scripts in scripts/ executable
if [ -d "$TOOLBOX_DIR/scripts" ]; then
    chmod +x "$TOOLBOX_DIR/scripts/"* 2>/dev/null
    echo "✅ Made scripts in $TOOLBOX_DIR/scripts executable"
fi

# Function to append a line to .bashrc only if it’s not already there
add_if_missing() {
    local line="$1"
    grep -qxF "$line" "$BASHRC" || echo "$line" >> "$BASHRC"
}

# Add toolbox/scripts to PATH
add_if_missing "export PATH=\"$TOOLBOX_DIR/scripts:\$PATH\""

# Add useful aliases
add_if_missing "alias toolbox=\"cd $TOOLBOX_DIR\""
add_if_missing "alias tpush='cd $TOOLBOX_DIR && git add . && git commit -m \"WIP\" && git push'"
add_if_missing "alias tpull='cd $TOOLBOX_DIR && git pull'"
add_if_missing "alias gitpush='bash $TOOLBOX_DIR/scripts/push_to_git.sh'"

echo "🔗 Added PATH and aliases to $BASHRC"

# Reload shell config
echo "♻️  Reloading .bashrc..."
source "$BASHRC"

echo "✅ Toolbox installed from: $TOOLBOX_DIR"

# Extract all newly added PATH lines from this install
ADDED_PATHS=$(grep "export PATH=\"$TOOLBOX_DIR" "$BASHRC" | sed -E 's#export PATH="([^"]+):\$PATH"#\1#')

if [ -n "$ADDED_PATHS" ]; then
    echo "📜 The following executable scripts are now available globally:"
    for dir in $ADDED_PATHS; do
        if [ -d "$dir" ]; then
            find "$dir" -maxdepth 1 -type f -executable -printf "  - %f\n"
        fi
    done
else
    echo "📜 No executable scripts were added to PATH (yet)."
fi

