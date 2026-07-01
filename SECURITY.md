# Security Policy

## Supported Versions

| Version | Support Status |
|---|---|
| 0.1.x | Full support — security fixes backported |
| < 0.1 | No longer supported |

## Reporting a Vulnerability

**Do NOT open a public GitHub issue for security vulnerabilities.**

Report privately using [GitHub Security Advisories](https://github.com/ek33450505/cast-mcp/security/advisories/new).

### What to Include

- **Version** — `cast-mcp version`
- **Operating system** — `sw_vers` (macOS) or `lsb_release -a` (Linux)
- **Which surface** — e.g., `cast-mcp-server.py`, the `cast_ask` tool, `install.sh`
- **Steps to reproduce** — minimal, clear reproduction steps
- **Impact** — what an attacker could do

### Response Timeline

| Severity | Acknowledgment | Fix Target |
|---|---|---|
| Critical | 48 hours | 14 days |
| High | 48 hours | 30 days |
| Medium / Low | 5 business days | Next release |

## Security Design Notes

cast-mcp is a read-only MCP server. Key design decisions:

- **Read-only by construction** — `cast.db` is opened with the SQLite URI `mode=ro`. Write attempts fail at the driver level, not by convention.
- **No arbitrary SQL** — only 5 curated tools are exposed. There is no "run this query" tool. (Anthropic's reference sqlite MCP was archived over a SQL-injection hole; cast-mcp deliberately does not repeat it.)
- **Parameterized queries only** — no user argument is ever f-string-interpolated into SQL. The one FTS5 free-text path quotes each token defensively; `LIKE` filters escape `%`/`_` metacharacters.
- **Bounded input** — every tool clamps `limit` to `1..200`. Request lines are capped at 1 MB before `json.loads` to guard against memory exhaustion.
- **No network** — stdio transport only. cast-mcp makes no external network requests.
- **No credentials** — cast-mcp handles no API keys, tokens, or secrets.
- **Fail-safe loop** — one malformed JSON-RPC frame is logged and skipped; it never kills the serve loop.

## Out of Scope

- Vulnerabilities in the Claude API or Anthropic services — report to [Anthropic](https://www.anthropic.com/security)
- Vulnerabilities in third-party tools (bash, Python, sqlite3, BATS)
- The contents of `~/.claude/cast.db` — that is a user-controlled input the server only reads

## Trust Model

cast-mcp assumes:

- The user controls `~/.claude/`. `cast.db` is trusted input for reporting purposes (read only, never executed).
- The `sqlite3` library is trustworthy. cast-mcp only reads from `cast.db`; it never writes.
- The Python interpreter is trustworthy. cast-mcp uses stdlib only (`sqlite3`, `json`, `os`, `sys`, `datetime`, `contextlib`, `pathlib`).
- The MCP client that launches `cast-mcp serve` is trusted (it controls stdin/stdout).
