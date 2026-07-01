# cast-mcp

Read-only MCP stdio server over `cast.db`. Extracted from the [claude-agent-team](https://github.com/ek33450505/claude-agent-team) flagship's `cast mcp` command.

## Layout

- `bin/cast-mcp` — bash launcher (`serve` / `config` / `status` / `version`). Resolves the server script, then `exec python3`.
- `scripts/cast-mcp-server.py` — the JSON-RPC 2.0 stdio server. Stdlib only.
- `install.sh` / `uninstall.sh` — copy launcher into `~/.local/bin`, server into `~/.local/lib/cast-mcp`.
- `tests/cast-mcp.bats` — isolated-temp-HOME BATS suite.

## Invariants (do not break)

- **Read-only.** `cast.db` is opened with URI `mode=ro`. Never add a write path.
- **No arbitrary SQL.** Only the curated `_TOOL_DISPATCH` tools. All queries parameterized.
- **Stdlib only.** No MCP SDK, no `pip install`.
- **Local-only.** stdio transport; no network calls.
- **No PII in the repo.** Paths in docs/tests are `~/` or `/Users/you/` placeholders — never real home paths, never real session IDs or `cast.db` contents.

## Test

```bash
bats tests/        # isolated temp HOME
bash -n bin/cast-mcp install.sh uninstall.sh
ruff check scripts/
```

## Server contract

- Protocol version `2025-06-18`, newline-delimited JSON-RPC 2.0 over stdio.
- serverInfo name `cast-record` (the identity MCP clients register).
- 5 tools: `cast_decisions`, `cast_incidents`, `cast_cost`, `cast_sessions`, `cast_ask`.
- 5 resources under `cast://`.
- `limit` clamped `1..200`; 1 MB request-line cap; missing tables degrade gracefully.
