#!/usr/bin/env bash
# Pull personal secrets from AWS Secrets Manager into local files per personal-secrets/manifest.json.

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

pulled=0
total=$(jq '.secrets | length' "$MANIFEST")

for i in $(seq 0 $((total - 1))); do
    entry=$(jq -c ".secrets[$i]" "$MANIFEST")
    name=$(echo "$entry"        | jq -r '.name')
    destination=$(resolve_home "$(echo "$entry" | jq -r '.destination')")
    format=$(echo "$entry"      | jq -r '.format')

    echo "Pulling $name -> $destination"

    # Use --output json (not text) — text mode strips newlines from multi-line secrets.
    content=$(aws secretsmanager get-secret-value \
        --secret-id "$name" \
        --profile   "$PROFILE" \
        --region    "$REGION" \
        --output    json | jq -r '.SecretString')

    mkdir -p "$(dirname "$destination")"

    if [ "$format" = "raw" ]; then
        printf '%s' "$content" > "$destination"
        permissions=$(echo "$entry" | jq -r '.permissions // empty')
        if [ -n "$permissions" ]; then
            chmod "$permissions" "$destination"
        fi
        echo "  Wrote raw file"
    elif [ "$format" = "json-merge" ]; then
        merge_path=$(echo "$entry" | jq -r '.merge_path')
        existing="{}"
        if [ -f "$destination" ]; then
            existing=$(cat "$destination")
        fi
        merged=$(echo "$existing" | jq --argjson new "$content" --arg key "$merge_path" '.[$key] = $new')
        printf '%s' "$merged" > "$destination"
        echo "  Merged '$merge_path' into $destination"
    else
        echo "  Unknown format '$format' for $name" >&2
        continue
    fi

    pulled=$((pulled + 1))
done

echo ""
echo "$pulled of $total secrets pulled."
