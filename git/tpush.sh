#!/bin/bash

cd "$TOOLBOXDIR" || {
    echo "❌ Could not cd into \$TOOLBOXDIR ($TOOLBOXDIR)"
    exit 1
}

# Detect detached HEAD (before doing anything)
CURRENT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null)
if [[ -z "$CURRENT_BRANCH" ]]; then
    echo "🚫 You are in a detached HEAD state. Please check out a branch before using tpush."
    echo "💡 Run: git checkout main  (or another branch)"
    exit 1
fi

DEFAULT_BRANCH="$CURRENT_BRANCH"

# 🧱 Check if a rebase is already in progress
if [ -d ".git/rebase-merge" ] || [ -d ".git/rebase-apply" ]; then
    echo -e "\n⚠️ You are already in the middle of a rebase!"
    CONFLICTED=$(git diff --name-only --diff-filter=U)

    if [[ -z "$CONFLICTED" ]]; then
        echo "❗ Rebase in progress but no conflicted files found."
        echo "👉 Run: git rebase --continue OR git rebase --abort"
        exit 1
    fi

    echo "🧨 Conflicted files from previous rebase:"
    echo "$CONFLICTED" | sed 's/^/  - /'

    read -p "🧩 Resolve these using [ours/theirs/skip/manual]? [manual]: " CHOICE
    CHOICE="${CHOICE:-manual}"

    if [[ "$CHOICE" == "ours" || "$CHOICE" == "theirs" ]]; then
        echo "⚙️ Resolving using '$CHOICE'..."
        for file in $CONFLICTED; do
            git checkout --$CHOICE "$file"
            git add "$file"
        done
        git rebase --continue
        git push
        echo "✅ Rebase complete, changes pushed."
        exit 0

    elif [[ "$CHOICE" == "skip" ]]; then
        git rebase --skip
        git push
        echo "⏭️ Skipped conflicted commit. Rebase continued and pushed."
        exit 0

    else
        echo "✋ Manual resolution selected. Finish rebase manually and retry tpush."
        echo "💡 Run: git status, git add <file>, git rebase --continue"
        exit 1
    fi
fi

# Ask for target branch
read -p "🪢 Push to which branch? [$DEFAULT_BRANCH]: " BRANCH
BRANCH="${BRANCH:-$DEFAULT_BRANCH}"

# Ask for commit message
read -p "💬 Enter commit message [WIP]: " COMMIT_MSG
COMMIT_MSG="${COMMIT_MSG:-WIP}"

# Stage and commit
git add .

if git diff --cached --quiet; then
    echo "🟢 Nothing to commit — working tree clean."
else
    git commit -m "$COMMIT_MSG"
fi

# Handle upstream tracking and rebase
if git rev-parse --abbrev-ref --symbolic-full-name "@{u}" >/dev/null 2>&1; then
    echo "🔁 Pulling with rebase from tracked remote..."
    git pull --rebase
else
    echo "🔗 No upstream set. Pulling from origin/$BRANCH with rebase..."
    git pull --rebase origin "$BRANCH"
    git branch --set-upstream-to=origin/"$BRANCH" "$BRANCH"
fi

# Check for new rebase conflicts
if [ -d ".git/rebase-merge" ] || [ -d ".git/rebase-apply" ]; then
    echo -e "\n🚨 Rebase conflict detected!"
    CONFLICTED=$(git diff --name-only --diff-filter=U)
    if [[ -z "$CONFLICTED" ]]; then
        echo "❗ Rebase conflict state but no files marked U. Something went wrong."
        exit 1
    fi

    echo "Conflicted files:"
    echo "$CONFLICTED" | sed 's/^/  - /'

    read -p "🧩 Resolve conflicts using [ours/theirs/skip/manual]? [manual]: " CHOICE
    CHOICE="${CHOICE:-manual}"

    if [[ "$CHOICE" == "ours" || "$CHOICE" == "theirs" ]]; then
        echo "⚙️ Resolving using '$CHOICE'..."
        for file in $CONFLICTED; do
            git checkout --$CHOICE "$file"
            git add "$file"
        done
        git rebase --continue
        git push
        echo "✅ Auto-resolved using '$CHOICE', rebase complete and pushed."
        exit 0

    elif [[ "$CHOICE" == "skip" ]]; then
        git rebase --skip
        git push
        echo "⏭️ Skipped conflicted commit. Rebase continued and pushed."
        exit 0

    else
        echo "✋ Manual conflict resolution selected. Resolve, then run: git rebase --continue"
        exit 1
    fi
fi

# Final push
git push

