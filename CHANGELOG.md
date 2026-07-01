# Changelog

## [0.1.0] — 2026-07-01

Initial release. Extracted from [claude-agent-team](https://github.com/ek33450505/claude-agent-team) v9's `cast mcp` command.

### Added
- Standalone `cast-mcp` launcher with `serve` / `config` / `status` / `version` subcommands
- Read-only MCP stdio server (`cast-mcp-server.py`) over `cast.db`:
  - Opened strictly read-only via SQLite URI `mode=ro`
  - Protocol version `2025-06-18`, newline-delimited JSON-RPC 2.0
  - **5 tools:** `cast_decisions`, `cast_incidents`, `cast_cost`, `cast_sessions`, `cast_ask`
  - **5 resources:** `cast://schema`, `cast://decisions/recent`, `cast://incidents/recent`, `cast://cost/summary`, `cast://sessions/recent`
  - `limit` clamped to `1..200` on every tool; parameterized queries only; no arbitrary-SQL tool
  - Missing tables degrade gracefully rather than erroring
- Idempotent `install.sh` / `uninstall.sh` — launcher into `~/.local/bin`, server into `~/.local/lib/cast-mcp`
- `CAST_DB_PATH` / `CAST_MCP_SERVER` env overrides

### Notes
- Python 3 stdlib only — no MCP SDK, no `pip install`
- Local-only: stdio transport, no network calls
