#!/usr/bin/env bash
# Link the repo's .claude/skills/* into ~/.claude/skills/ as symlinks.
#
# For each subdirectory under <repo>/.claude/skills/, creates a symlink at
# $HOME/.claude/skills/<name> pointing at the repo path. Skips entries that
# already exist (real dir, symlink, or anything else) — never overwrites or
# deletes anything in the target.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_SKILLS="$(cd "$SCRIPT_DIR/../.claude/skills" && pwd)"
TARGET_ROOT="$HOME/.claude/skills"

mkdir -p "$TARGET_ROOT"

linked=0
skipped=0

for source in "$REPO_SKILLS"/*/; do
    [ -d "$source" ] || continue
    name="$(basename "$source")"
    target="$TARGET_ROOT/$name"

    if [ -e "$target" ] || [ -L "$target" ]; then
        echo "SKIP: $name (already exists at $target — remove manually if you want it linked)"
        skipped=$((skipped + 1))
        continue
    fi

    # Strip trailing slash from source for cleaner readlink output.
    ln -s "${source%/}" "$target"
    echo "LINK: $name -> ${source%/}"
    linked=$((linked + 1))
done

echo ""
echo "$linked linked, $skipped skipped."
