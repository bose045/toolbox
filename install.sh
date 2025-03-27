#!/bin/bash

echo "🔧 Starting Toolbox Installer..."

# Ask for install location (default: ~/bin/toolbox)
read -p "Install toolbox to [~/bin/toolbox]: " INSTALL_PATH
INSTALL_PATH="${INSTALL_PATH:-$HOME/bin/toolbox}"
INSTALL_PATH="${INSTALL_PATH/#\~/$HOME}"

# Abort if already exists unless user agrees to overwrite
if [ -d "$INSTALL_PATH" ]; then
    read -p "⚠️  Toolbox already exists at $INSTALL_PATH. Overwrite? [y/N]: " OVERWRITE
    OVERWRITE=${OVERWRITE,,}
    if [[ "$OVERWRITE" != "y" && "$OVERWRITE" != "yes" ]]; then
        echo "🚫 Aborting installation. Nothing was changed."
        exit 1
    fi
    echo "♻️  Overwriting existing toolbox..."
fi


mkdir -p "$INSTALL_PATH"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
rsync -av --delete --exclude='.git' "$SOURCE_DIR/" "$INSTALL_PATH/"

TOOLBOXDIR="$INSTALL_PATH"
BASHRC="$HOME/.bashrc"
ALIAS_FILE="$TOOLBOXDIR/alias_def.txt"

# Append to .bashrc if missing
add_if_missing() {
    local line="$1"
    grep -qxF "$line" "$BASHRC" || echo "$line" >> "$BASHRC"
}

# Ensure all .sh scripts are executable
echo "🔍 Making all *.sh files executable..."
find "$TOOLBOXDIR" -type f -name "*.sh" -exec chmod +x {} \;
echo "✅ Made all .sh scripts in toolbox executable"

# Prepare alias_def.txt
[ -f "$ALIAS_FILE" ] || touch "$ALIAS_FILE"

# Bashrc updates
add_if_missing "export TOOLBOXDIR=\"$TOOLBOXDIR\""
add_if_missing "export PATH=\"\$TOOLBOXDIR/scripts:\$PATH\""
add_if_missing "source \$TOOLBOXDIR/alias_def.txt"
add_if_missing "alias toolbox=\"cd \$TOOLBOXDIR\""
add_if_missing "alias tpull='cd \$TOOLBOXDIR && git pull'"

echo "🔗 Updated $BASHRC with TOOLBOXDIR and aliases"
echo "♻️  Reloading $BASHRC..."
source "$BASHRC"

echo "✅ Toolbox installed at: $TOOLBOXDIR"

# List executable scripts
echo
echo "📜 Searching for executable .sh scripts inside $TOOLBOXDIR..."
EXECUTABLES=$(find "$TOOLBOXDIR" -type f -name "*.sh" -executable)
if [[ -n "$EXECUTABLES" ]]; then
    echo "$EXECUTABLES" | sed "s|$TOOLBOXDIR/|  - |"
else
    echo "  (No executable .sh scripts found.)"
fi

# List defined aliases
echo
echo "📘 Aliases currently defined in $ALIAS_FILE:"
if [ -s "$ALIAS_FILE" ]; then
    grep '^alias ' "$ALIAS_FILE" | sed 's/^/  - /'
else
    echo "  (No aliases yet. Use set_alias.sh to add some!)"
fi

# 🆕 Optionally initialize Git and link to GitHub repo
echo
read -p "🔗 Link this toolbox install to a GitHub repo? [y/N]: " LINK_GIT
LINK_GIT=${LINK_GIT,,}

if [[ "$LINK_GIT" == "y" || "$LINK_GIT" == "yes" ]]; then
    cd "$TOOLBOXDIR"

    if [ -d ".git" ]; then
        echo "✅ Git already initialized in $TOOLBOXDIR"
    else
        git init
        git branch -M main
        echo "📦 Initialized Git repository in $TOOLBOXDIR"
    fi

    read -p "GitHub username [bose045]: " GH_USER
    GH_USER="${GH_USER:-bose045}"

    read -p "GitHub repo name [toolbox]: " GH_REPO
    GH_REPO="${GH_REPO:-toolbox}"

    read -p "Use SSH or HTTPS? [ssh]: " GH_METHOD
    GH_METHOD="${GH_METHOD:-ssh}"

    if [[ "$GH_METHOD" == "ssh" ]]; then
        GH_REMOTE="git@github.com:${GH_USER}/${GH_REPO}.git"
    else
        GH_REMOTE="https://github.com/${GH_USER}/${GH_REPO}.git"
    fi

    if git remote | grep -q origin; then
        echo "⚠️  Remote 'origin' already exists. Skipping."
    else
        git remote add origin "$GH_REMOTE"
        echo "✅ Remote origin set to $GH_REMOTE"
    fi

    echo "ℹ️  You can now: cd \$TOOLBOXDIR && git pull/push"
fi

