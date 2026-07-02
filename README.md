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
**Core Framework**

| Repo | Description | Latest | Install |
|---|---|---|---|
| [claude-agent-team](https://github.com/ek33450505/claude-agent-team) | Local-first multi-agent control plane — specialist agents, quality gates, hook enforcement, and the tamper-evident cast.db execution record. | ![](https://img.shields.io/github/v/release/ek33450505/claude-agent-team?style=flat-square) | `brew tap ek33450505/cast && brew install cast` |

**Observability**

| Repo | Description | Latest | Install |
|---|---|---|---|
| [claude-code-dashboard](https://github.com/ek33450505/claude-code-dashboard) | React observability UI — sessions, agent analytics, hook health, memory browser, SQLite explorer. | ![](https://img.shields.io/github/v/release/ek33450505/claude-code-dashboard?style=flat-square) | Clone from GitHub |
| [cast-desktop](https://github.com/ek33450505/cast-desktop) | Tauri 2 native app — embedded PTY terminal, command palette, 11 dashboard views. | ![](https://img.shields.io/github/v/release/ek33450505/cast-desktop?style=flat-square) | `brew tap ek33450505/homebrew-cast-desktop && brew install cast-desktop` |

**Standalone Packages**

| Repo | Description | Latest | Install |
|---|---|---|---|
| [cast-mcp](https://github.com/ek33450505/cast-mcp) | Read-only MCP server over the Claude Code execution record (cast.db) — dispatch decisions, incidents, cost, sessions, and full-text search as 5 MCP tools + 5 resources. stdlib-only, strictly read-only. | ![](https://img.shields.io/github/v/release/ek33450505/cast-mcp?style=flat-square) | `brew tap ek33450505/cast-mcp && brew install cast-mcp` |
| [cast-ledger](https://github.com/ek33450505/cast-ledger) | Signed, hash-chained, tamper-evident session receipts for Claude Code — SHA-256-stamped audit receipts from cast.db with `--verify`, plus an optional provenance hash-chain across sessions. | ![](https://img.shields.io/github/v/release/ek33450505/cast-ledger?style=flat-square) | `brew tap ek33450505/cast-ledger && brew install cast-ledger` |
| [cast-predict](https://github.com/ek33450505/cast-predict) | Telemetry-driven dispatch prediction for Claude Code — reads cast.db to predict a task's likely cost, suggest agents, and surface related past incidents before you run it. | ![](https://img.shields.io/github/v/release/ek33450505/cast-predict?style=flat-square) | `brew tap ek33450505/cast-predict && brew install cast-predict` |
| [cast-memory](https://github.com/ek33450505/cast-memory) | Persistent agent memory for Claude Code — FTS5 full-text search, weighted relevance, temporal validity, Ollama embeddings, and weekly consolidation over cast.db. | ![](https://img.shields.io/github/v/release/ek33450505/cast-memory?style=flat-square) | `brew tap ek33450505/cast-memory && brew install cast-memory` |
| [cast-doctor](https://github.com/ek33450505/cast-doctor) | Standalone read-only health check for any Claude Code install — validates hooks, MCP config, agent frontmatter, cast.db core schema, and stale memories without the full CAST framework. | ![](https://img.shields.io/github/v/release/ek33450505/cast-doctor?style=flat-square) | `brew tap ek33450505/cast-doctor && brew install cast-doctor` |
| [cast-time](https://github.com/ek33450505/cast-time) | Gives Claude Code a clock — injects local time, timezone, and a semantic time-of-day bucket at every SessionStart. | ![](https://img.shields.io/github/v/release/ek33450505/cast-time?style=flat-square) | `brew tap ek33450505/cast-time && brew install cast-time` |
| [cast-claudes_journal](https://github.com/ek33450505/cast-claudes_journal) | Three-hook journaling for Claude Code (Stop/SessionStart/UserPromptSubmit) — maintains Claude's perspective and working memory across sessions as Obsidian-compatible markdown in ~/Documents/Claude/. | ![](https://img.shields.io/github/v/release/ek33450505/cast-claudes_journal?style=flat-square) | `brew tap ek33450505/homebrew-claudes-journal && brew install claudes-journal` |
<!-- ECOSYSTEM_END -->

## License

[MIT](LICENSE) © Edward Kubiak
