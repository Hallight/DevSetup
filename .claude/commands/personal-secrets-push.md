---
description: Push personal secrets (AWS creds, Claude MCP servers) from local files up to AWS Secrets Manager.
---

Run the OS-appropriate push script to upload the local `~/.aws/credentials` and the `mcpServers` subtree of `~/.claude.json` into AWS Secrets Manager. The first run from a machine where the secrets don't yet exist in AWS doubles as the initial seeding step — the script calls `create-secret` when a secret is new and `put-secret-value` when it already exists.

1. Detect the OS:
   - Windows → run `pwsh -File scripts/personal-secrets-push.ps1` from the repo root (fall back to `powershell -File` if `pwsh` is not on PATH).
   - macOS / Linux → run `bash scripts/personal-secrets-push.sh` from the repo root.

2. Show the script output verbatim and summarize the final `<c> created, <u> updated, <s> skipped` line.

3. If anything was skipped, name the entries that failed and surface the AWS error message. If the failure is auth-related, remind the user about `aws configure --profile mah13090-admin`.

Push deliberately — local files become the source of truth in AWS the moment this runs. Do not run on a machine where the local files are out of date relative to AWS.
