#!/bin/bash
# Helper function
show_help() {
cat << EOF
gitpush — Interactively commit and push the current Git repository to GitHub

Usage:
  gitpush
  bash push_to_git.sh

What it does:
  - Detects existing GitHub repo from remote (if available)
  - Prompts for repo name, GitHub username (default: bose045), and SSH/HTTPS
  - Initializes Git repo if it doesn't exist
  - Adds all new and modified files
  - Re-stages tracked files to include permission changes (e.g., chmod +x)
  - Commits with a user-provided message
  - Pushes to origin/main and sets up tracking if needed

Options:
  -h, --help        Show this help message and exit

Example:
  gitpush
EOF
exit 0
}

# Show help if requested
[[ "$1" == "--help" || "$1" == "-h" ]] && show_help

# Try to detect default repo name from remote origin URL (supports SSH and HTTPS)
DEFAULT_REPO=$(git remote get-url origin 2>/dev/null | \
    sed -E 's#(git@|https://)github.com[:/](.+)/(.+)\.git#\3#')

# Ask for repo name (use default if available, ask until non-empty)
while true; do
    read -p "Enter GitHub repo name [${DEFAULT_REPO}]: " REPO_NAME
    REPO_NAME="${REPO_NAME:-$DEFAULT_REPO}"
    if [[ -n "$REPO_NAME" ]]; then
        break
    else
        echo "Repo name cannot be empty. Please enter it."
    fi
done

# Ask for GitHub username (default: bose045)
read -p "Enter your GitHub username [bose045]: " USERNAME
USERNAME="${USERNAME:-bose045}"

# Ask for SSH or HTTPS (default: ssh)
read -p "Use SSH or HTTPS? [ssh]: " METHOD
METHOD="${METHOD:-ssh}"

# Build remote URL
if [[ "$METHOD" == "ssh" ]]; then
    REMOTE_URL="git@github.com:${USERNAME}/${REPO_NAME}.git"
elif [[ "$METHOD" == "https" ]]; then
    REMOTE_URL="https://github.com/${USERNAME}/${REPO_NAME}.git"
else
    echo "Invalid input. Use 'ssh' or 'https'."
    exit 1
fi

# Ask for commit message
read -p "Enter commit message: " COMMIT_MSG
COMMIT_MSG="${COMMIT_MSG:-Quick update}"

# Initialize git repo if needed
if [ ! -d ".git" ]; then
    git init
    git branch -M main
    echo "Initialized empty Git repository."
fi

# Add remote if not already added
if ! git remote | grep -q origin; then
    git remote add origin "$REMOTE_URL"
    echo "Added remote origin: $REMOTE_URL"
else
    echo "Remote origin already exists."
fi

# Re-add all tracked files to catch permission changes
git ls-files -s | awk '{print $4}' | xargs git add

# Stage new files and modified content
git add .

# Commit and push
git commit -m "$COMMIT_MSG"
git push -u origin main

