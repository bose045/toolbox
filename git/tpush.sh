#!/bin/bash

cd "$TOOLBOXDIR" || {
    echo "❌ Could not cd into \$TOOLBOXDIR ($TOOLBOXDIR)"
    exit 1
}

# Detect current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
DEFAULT_BRANCH="${CURRENT_BRANCH:-main}"

read -p "🪢 Push to which branch? [$DEFAULT_BRANCH]: " BRANCH
BRANCH="${BRANCH:-$DEFAULT_BRANCH}"

read -p "💬 Enter commit message [WIP]: " COMMIT_MSG
COMMIT_MSG="${COMMIT_MSG:-WIP}"

# Stage everything
git add .

# Commit if needed
if git diff --cached --quiet; then
    echo "🟢 Nothing to commit — working tree clean."
else
    git commit -m "$COMMIT_MSG"
fi

# Handle tracking
if git rev-parse --abbrev-ref --symbolic-full-name "@{u}" >/dev/null 2>&1; then
    echo "🔁 Pulling with rebase from tracked remote..."
    git pull --rebase
else
    echo "🔗 No upstream set. Pulling from origin/$BRANCH with rebase..."
    git pull --rebase origin "$BRANCH"
    git branch --set-upstream-to=origin/"$BRANCH" "$BRANCH"
fi

# Detect rebase conflict
if [ -d ".git/rebase-merge" ] || [ -d ".git/rebase-apply" ]; then
    echo -e "\n🚨 Rebase conflict detected!"
    echo "Conflicted files:"
    git diff --name-only --diff-filter=U | sed 's/^/  - /'

    echo
    read -p "🧩 Resolve conflicts using [ours/theirs/skip/manual]? [manual]: " CHOICE
    CHOICE="${CHOICE:-manual}"

    if [[ "$CHOICE" == "ours" || "$CHOICE" == "theirs" ]]; then
        echo "⚙️ Resolving all conflicts using: $CHOICE"
        for file in $(git diff --name-only --diff-filter=U); do
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
        echo "⏭️ Skipped the conflicted commit. Rebase continued and pushed."
        exit 0

    else
        echo -e "✋ Manual conflict resolution selected.\n"
        echo "🧾 Do this:"
        echo "  1. Run:    git status"
        echo "  2. Fix:    each conflicted file"
        echo "  3. Then:   git add <file>"
        echo "  4. Finish: git rebase --continue"
        echo "  5. Retry:  tpush"
        exit 1
    fi
fi

# Push final changes
git push

