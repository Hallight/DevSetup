---
description: Pull personal secrets (AWS creds, Claude MCP servers) from AWS Secrets Manager into local files.
---

Run the OS-appropriate pull script to restore personal secrets from AWS Secrets Manager into `~/.aws/credentials` and the `mcpServers` subtree of `~/.claude.json`. The script never touches the rest of `~/.claude.json`.

1. Detect the OS:
   - Windows → run `pwsh -File scripts/personal-secrets-pull.ps1` from the repo root (fall back to `powershell -File` if `pwsh` is not on PATH).
   - macOS / Linux → run `bash scripts/personal-secrets-pull.sh` from the repo root.

2. Show the script output verbatim and summarize the final `<n> of <total> secrets pulled` line.

3. If the script reports an auth or AWS error, surface it clearly and remind the user that they need to run `aws configure --profile mah13090-admin` once with the keys from their password manager before this command will work.

Do not modify the script itself. Do not delete anything in the user's home directory beyond the in-place rewrites the script performs.
