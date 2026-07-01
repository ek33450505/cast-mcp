# cast-mcp

A **read-only MCP server** over your Claude Code execution record (`cast.db`). Exposes recent dispatch decisions, past incidents, cost aggregation, sessions, and full-text search across the whole record as **5 MCP tools + 5 resources** — so any MCP client (Claude Code, Claude Desktop, or your own) can query what your agents actually did.

- **Strictly read-only.** `cast.db` is opened with SQLite URI `mode=ro` — write attempts fail at the driver level, not by convention.
- **No arbitrary SQL.** Only 5 curated, parameterized tools. No SQL-injection surface (the archived reference-sqlite MCP shipped one; this deliberately does not).
- **Local-only.** stdio transport, no network calls, no telemetry. Nothing leaves your machine.
- **Zero dependencies.** Python 3 stdlib only — no MCP SDK, no `pip install`.

Works **without** the full CAST framework. Point it at any `cast.db` and it serves.

## Install (Homebrew)

```bash
brew tap ek33450505/cast-mcp && brew install cast-mcp
```

## Manual install

```bash
git clone https://github.com/ek33450505/cast-mcp.git
cd cast-mcp
bash install.sh
```

`install.sh` copies the `cast-mcp` launcher into `~/.local/bin` and the server into `~/.local/lib/cast-mcp/`. It is idempotent — safe to re-run.

## Register with an MCP client

Print the config snippet:

```bash
cast-mcp config
```

Add a project-level `.mcp.json`:

```json
{
  "mcpServers": {
    "cast-record": {
      "type": "stdio",
      "command": "cast-mcp",
      "args": ["serve"]
    }
  }
}
```

Or register via the Claude Code CLI:

```bash
claude mcp add cast-record -- cast-mcp serve
```

Check the server is reachable and the handshake succeeds:

```bash
cast-mcp status
```

## Usage

```bash
cast-mcp serve      # run the read-only MCP stdio server (invoked by MCP clients)
cast-mcp config     # print the .mcp.json entry / `claude mcp add` line
cast-mcp status     # verify cast.db is present and the server handshake succeeds
cast-mcp version    # print version
```

`cast-mcp serve` speaks newline-delimited JSON-RPC 2.0 over stdio (MCP protocol `2025-06-18`). You do not normally run it by hand — the MCP client launches it.

### Tools

| Tool | What it returns |
|---|---|
| `cast_decisions` | Recent agent-dispatch routing decisions |
| `cast_incidents` | Past incident log — problem + fix summaries (optional keyword filter) |
| `cast_cost` | Token / USD cost aggregation, grouped `by` agent, branch, or session |
| `cast_sessions` | Recent sessions (id, project, started/ended, status) |
| `cast_ask` | FTS5 full-text search across the entire record |

Every tool clamps `limit` to `1..200`. Missing tables degrade to a plain message rather than an error.

### Resources

| URI | Content |
|---|---|
| `cast://schema` | Exposed tables and their current row counts |
| `cast://decisions/recent` | Last 10 dispatch decisions |
| `cast://incidents/recent` | Last 10 incidents |
| `cast://cost/summary` | Cost by agent, top 10 |
| `cast://sessions/recent` | Last 10 sessions |

## Configuration

| Env var | Default | Purpose |
|---|---|---|
| `CAST_DB_PATH` | `~/.claude/cast.db` | Path to the record database (opened read-only) |
| `CAST_MCP_SERVER` | *(auto-resolved)* | Override the server script path (for advanced/dev use) |

## Security

- Read-only by construction (`mode=ro` URI) — the server cannot write to `cast.db`.
- All queries use bound parameters; no user input is interpolated into SQL.
- No arbitrary-SQL tool is exposed.
- Request lines are capped at 1 MB; one malformed frame is logged and skipped, never crashing the loop.

See [SECURITY.md](SECURITY.md) for the full trust model.

## Requirements

- **Python 3** (stdlib only)
- **sqlite3** — for the `status` handshake and at runtime
- A `cast.db` to serve (created by [claude-agent-team](https://github.com/ek33450505/claude-agent-team) or any CAST tool)

## Part of the CAST ecosystem

Extracted from [claude-agent-team](https://github.com/ek33450505/claude-agent-team)'s `cast mcp` command.

<!-- ECOSYSTEM_START -->
| Repo | Description | Install |
|---|---|---|
| [claude-agent-team](https://github.com/ek33450505/claude-agent-team) | The CAST flagship — the local, inspectable, tamper-evident record of what your agents did. | `git clone` |
<!-- ECOSYSTEM_END -->

## License

[MIT](LICENSE) © Edward Kubiak
