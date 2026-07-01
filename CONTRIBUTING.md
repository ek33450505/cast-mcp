# Contributing to cast-mcp

Thanks for your interest! cast-mcp is a focused, read-only MCP server over `cast.db`. Contributions that add curated read-only tools/resources, harden the query surface, or improve cross-platform support are welcome.

## Prerequisites

- **bash** + **python3** — both ship with macOS / standard Linux
- **sqlite3** — required for the `status` handshake and at runtime
- **BATS** — `brew install bats-core` (macOS) or `apt-get install bats` (Ubuntu)
- **ruff** (optional, for linting Python) — `pip install ruff` or `brew install ruff`

Stdlib Python only — no MCP SDK, no third-party dependencies.

## Quick Start

```bash
git clone https://github.com/ek33450505/cast-mcp
cd cast-mcp
bash install.sh
cast-mcp status
```

`install.sh` is idempotent — safe to re-run.

## How to Modify

**Launcher** (`bin/cast-mcp`): thin bash wrapper — `serve` / `config` / `status` / `version`.

**Server** (`scripts/cast-mcp-server.py`): the JSON-RPC 2.0 stdio server. To add a tool:

1. Write a `_fetch_*` function that opens a read-only connection and runs a **parameterized** query (never f-string user input into SQL).
2. Add a `_tool_*` dispatch wrapper that clamps `limit` via `_clamp_limit`.
3. Register it in `_TOOL_DISPATCH` and add its `inputSchema` to `TOOL_DEFS`.
4. If it exposes a new table, add the table to `_EXPOSED_TABLES` and consider a matching resource.
5. If your change adds a write of any kind, STOP — cast-mcp is strictly read-only.

## PR Checklist

- [ ] `bash install.sh && bash uninstall.sh` round-trip clean
- [ ] BATS tests pass: `bats tests/`
- [ ] `bash -n bin/cast-mcp install.sh uninstall.sh` — all syntax-check
- [ ] `ruff check scripts/` clean (if ruff installed)
- [ ] `cast-mcp status` handshake succeeds against a real `cast.db`
- [ ] No writes to `cast.db` anywhere — the server opens `mode=ro`
- [ ] No arbitrary-SQL tool; all queries parameterized
- [ ] No hardcoded `/Users/<name>/` paths — use `$HOME` / `~/`
- [ ] `CHANGELOG.md` updated for user-visible changes

## Code Style

- All scripts: `set -euo pipefail`
- Quote variable expansions: `"$var"`
- Use `[[ ]]` for conditionals, not `[ ]`
- ShellCheck clean — no warnings
- Python: stdlib only, `ruff`-clean

## Reporting issues

Use the GitHub issue templates under `.github/ISSUE_TEMPLATE/`. For security issues, see [SECURITY.md](SECURITY.md) — do not open a public issue.
