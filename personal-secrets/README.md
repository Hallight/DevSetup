# `personal-secrets/` — fresh-machine bootstrap via AWS Secrets Manager

Two paired slash commands let any machine pull / push a small set of personal secrets to AWS Secrets Manager:

- **`/personal-secrets-pull`** — fetch secrets from AWS and write them to local files. Run this once on each new machine after `aws configure --profile mah13090-admin`.
- **`/personal-secrets-push`** — read local files and upload them to AWS. Run this on any machine after rotating an AWS key, adding a new MCP server, or otherwise changing one of the managed files.

The first ever run of `/personal-secrets-push` from a machine that already has the secrets locally is also the seeding step — it creates the secrets in AWS Secrets Manager (rather than updating them).

## Files in this directory

- **`manifest.json`** — non-secret declarative mapping from `secret-id` in AWS Secrets Manager to local file path + format. Edit this when you want to add or remove a managed secret.
- This `README.md` — what you're reading.

No secret values are stored here.

## Managed secrets

| Secret id | Source file | Format | Notes |
|---|---|---|---|
| `personal/aws/credentials` | `~/.aws/credentials` | `raw` | Whole INI file body. Holds the 4 named profiles (default, brosketeers-website, mainstreetautomation-ci-user, meeplemates-ci-user). |
| `personal/claude/mcp-servers` | `~/.claude.json` (subtree) | `json-merge` | Just the `mcpServers` top-level object. Pull merges it back into the existing file so per-project state, `numStartups`, and other Claude Code internals are preserved. |

`~/.aws/config` is **not** managed here — it's region-only and not secret. If you change it, copy by hand.

## Manifest format

```json
{
  "region": "us-west-2",
  "profile": "mah13090-admin",
  "secrets": [
    { "name": "personal/aws/credentials", "destination": "~/.aws/credentials", "format": "raw", "permissions": "0600" },
    { "name": "personal/claude/mcp-servers", "destination": "~/.claude.json", "format": "json-merge", "merge_path": "mcpServers" }
  ]
}
```

- `region` — AWS region the secrets live in. Pinned in the manifest so a CLI default doesn't drift the pull/push to the wrong account.
- `profile` — AWS CLI profile name to use for both directions. Maps to the `mah13090-admin` IAM user, which has broad enough permissions to read/write Secrets Manager. Each new machine runs `aws configure --profile mah13090-admin` once to seed this profile.
- `secrets[].format`:
  - `raw` — write `SecretString` verbatim to `destination`.
  - `json-merge` — read the existing JSON at `destination` (or `{}` if missing), parse the secret as JSON, and replace the top-level `merge_path` key with that value. Every other key in the file is preserved.
- `secrets[].permissions` — applied via `chmod` on macOS/Linux. Ignored on Windows.

## Adding a new managed secret

1. Append a new entry to `manifest.json`:
   ```json
   { "name": "personal/<area>/<thing>", "destination": "~/path/to/file", "format": "raw" }
   ```
2. Run `/personal-secrets-push` once on a machine where the source file is correct — this creates the secret in AWS the first time and updates it on subsequent runs.
3. On every other machine, run `/personal-secrets-pull` to fetch the new secret onto disk.

## Rotation

For an AWS key rotation: rotate via AWS console, run `aws configure --profile <name>` to overwrite the local entry, run `/personal-secrets-push`. Other machines pull on next bootstrap.

For an MCP token rotation: edit `~/.claude.json` (or use `claude mcp` CLI to update the env var), then `/personal-secrets-push`.

## Security

- The `mah13090-admin` IAM user's keys are the cross-machine root of trust. Keep them in a password manager.
- All secrets live under the `personal/` prefix in Secrets Manager. Keep new ones under that same prefix so future IAM scoping (if ever introduced) stays one wildcard.
- The repo never holds secret values — only `manifest.json` (a structural pointer file).
- `~/.claude.json` is preserved on `json-merge` — only the `mcpServers` subtree is touched. Per-project state and other Claude Code internals are untouched.
