#!/usr/bin/env bash
# Push personal secrets from local files into AWS Secrets Manager per personal-secrets/manifest.json.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFEST="$REPO_ROOT/personal-secrets/manifest.json"

if [ ! -f "$MANIFEST" ]; then
    echo "Manifest not found at $MANIFEST" >&2
    exit 1
fi

command -v aws >/dev/null 2>&1 || { echo "aws CLI not installed. https://aws.amazon.com/cli/" >&2; exit 1; }
command -v jq  >/dev/null 2>&1 || { echo "jq not installed. brew install jq / apt install jq" >&2; exit 1; }

REGION=$(jq -r '.region'  "$MANIFEST")
PROFILE=$(jq -r '.profile' "$MANIFEST")

if ! aws sts get-caller-identity --profile "$PROFILE" >/dev/null 2>&1; then
    echo "Profile '$PROFILE' not authenticated. Run: aws configure --profile $PROFILE" >&2
    exit 1
fi

resolve_home() {
    local p="$1"
    printf '%s' "${p/#\~\//$HOME/}"
}

created=0
updated=0
skipped=0
total=$(jq '.secrets | length' "$MANIFEST")

for i in $(seq 0 $((total - 1))); do
    entry=$(jq -c ".secrets[$i]" "$MANIFEST")
    name=$(echo "$entry"   | jq -r '.name')
    source=$(resolve_home "$(echo "$entry" | jq -r '.destination')")
    format=$(echo "$entry" | jq -r '.format')

    if [ ! -f "$source" ]; then
        echo "Source missing for $name: $source" >&2
        skipped=$((skipped + 1))
        continue
    fi

    case "$format" in
        raw)
            content=$(cat "$source")
            ;;
        json-merge)
            merge_path=$(echo "$entry" | jq -r '.merge_path')
            content=$(jq -c ".[\"$merge_path\"] // empty" "$source")
            if [ -z "$content" ]; then
                echo "Source $source has no '$merge_path' key, skipping" >&2
                skipped=$((skipped + 1))
                continue
            fi
            ;;
        *)
            echo "Unknown format '$format' for $name" >&2
            skipped=$((skipped + 1))
            continue
            ;;
    esac

    tmp=$(mktemp)
    trap 'rm -f "$tmp"' EXIT
    printf '%s' "$content" > "$tmp"
    secret_arg="file://$tmp"

    if aws secretsmanager describe-secret \
            --secret-id "$name" --profile "$PROFILE" --region "$REGION" >/dev/null 2>&1; then
        if aws secretsmanager put-secret-value \
                --secret-id "$name" \
                --profile   "$PROFILE" \
                --region    "$REGION" \
                --secret-string "$secret_arg" >/dev/null; then
            echo "Updated $name"
            updated=$((updated + 1))
        else
            echo "Failed to update $name" >&2
            skipped=$((skipped + 1))
        fi
    else
        if aws secretsmanager create-secret \
                --name      "$name" \
                --profile   "$PROFILE" \
                --region    "$REGION" \
                --secret-string "$secret_arg" >/dev/null; then
            echo "Created $name"
            created=$((created + 1))
        else
            echo "Failed to create $name" >&2
            skipped=$((skipped + 1))
        fi
    fi

    rm -f "$tmp"
    trap - EXIT
done

echo ""
echo "$created created, $updated updated, $skipped skipped."
