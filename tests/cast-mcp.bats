#!/usr/bin/env bats
# tests/cast-mcp.bats — BATS suite for cast-mcp launcher + MCP server.
# Isolated temp HOME — never touches the real ~/.claude.

# ---------------------------------------------------------------------------
# Setup / teardown
# ---------------------------------------------------------------------------
setup() {
  REPO_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  CLI="$REPO_DIR/bin/cast-mcp"
  SERVER="$REPO_DIR/scripts/cast-mcp-server.py"

  ORIG_HOME="$HOME"
  HOME="$(mktemp -d)"
  export HOME
  mkdir -p "$HOME/.claude/logs"

  export CAST_DB_PATH="$BATS_TEST_TMPDIR/test-mcp-$$.db"
}

teardown() {
  rm -f "$CAST_DB_PATH"
  rm -rf "$HOME"
  HOME="$ORIG_HOME"
  export HOME
}

# Helper: build a minimal cast.db with required tables (no record_fts).
_make_db() {
  command -v sqlite3 >/dev/null || skip "sqlite3 not available"
  sqlite3 "$CAST_DB_PATH" "
    CREATE TABLE sessions(
      id TEXT, project TEXT, project_root TEXT,
      started_at TEXT, ended_at TEXT, status TEXT, deleted_at TEXT
    );
    CREATE TABLE agent_runs(
      session_id TEXT, agent TEXT, model TEXT, cost_usd REAL
    );
    CREATE TABLE dispatch_decisions(
      id INTEGER, session_id TEXT, prompt_snippet TEXT, chosen_agent TEXT,
      model TEXT, effort TEXT, parallel INTEGER, created_at TEXT, outcome TEXT
    );
    CREATE TABLE incidents(
      id INTEGER, occurred_at TEXT, problem_summary TEXT, fix_summary TEXT,
      related_files TEXT, related_commit TEXT, resolution_status TEXT, surfaced_by TEXT
    );
  "
}

# ---------------------------------------------------------------------------
# 1. CLI is executable
# ---------------------------------------------------------------------------
@test "CLI is executable" {
  [ -x "$CLI" ]
}

# ---------------------------------------------------------------------------
# 2. version prints cast-mcp v
# ---------------------------------------------------------------------------
@test "version prints cast-mcp v" {
  run bash "$CLI" version
  [ "$status" -eq 0 ]
  [[ "$output" == *"cast-mcp v"* ]]
}

# ---------------------------------------------------------------------------
# 3. help prints Usage:
# ---------------------------------------------------------------------------
@test "help prints Usage:" {
  run bash "$CLI" help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
}

# ---------------------------------------------------------------------------
# 4. unknown subcommand exits non-zero
# ---------------------------------------------------------------------------
@test "unknown subcommand exits non-zero" {
  run bash "$CLI" --nope
  [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# 5. CLAUDE_SUBPROCESS=1 exits 0 silently
# ---------------------------------------------------------------------------
@test "CLAUDE_SUBPROCESS=1 exits 0 silently" {
  run env CLAUDE_SUBPROCESS=1 bash "$CLI"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ---------------------------------------------------------------------------
# 6. config prints mcpServers snippet and claude mcp add line
# ---------------------------------------------------------------------------
@test "config prints mcpServers snippet and claude mcp add line" {
  run bash "$CLI" config
  [ "$status" -eq 0 ]
  [[ "$output" == *"cast-record"* ]]
  [[ "$output" == *"claude mcp add"* ]]
}

# ---------------------------------------------------------------------------
# 7. status fails cleanly when cast.db absent
# ---------------------------------------------------------------------------
@test "status fails cleanly when cast.db absent" {
  export CAST_DB_PATH="$BATS_TEST_TMPDIR/nonexistent-$$.db"
  run bash "$CLI" status
  [ "$status" -ne 0 ]
  [[ "$output" == *"cast.db not found"* ]]
}

# ---------------------------------------------------------------------------
# 8. server initialize handshake returns protocolVersion, 2025-06-18, cast-record
# ---------------------------------------------------------------------------
@test "server initialize handshake returns protocolVersion" {
  _make_db
  result="$(printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' | python3 "$SERVER")"
  [[ "$result" == *'"protocolVersion"'* ]]
  [[ "$result" == *'2025-06-18'* ]]
  [[ "$result" == *'cast-record'* ]]
}

# ---------------------------------------------------------------------------
# 9. server tools/list returns exactly 5 tools
# ---------------------------------------------------------------------------
@test "server tools/list returns 5 tools" {
  _make_db
  result="$(printf '%s\n' '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' | python3 "$SERVER")"
  count="$(printf '%s\n' "$result" | python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d['result']['tools']))")"
  [ "$count" -eq 5 ]
}

# ---------------------------------------------------------------------------
# 10. server resources/list returns exactly 5 resources
# ---------------------------------------------------------------------------
@test "server resources/list returns 5 resources" {
  _make_db
  result="$(printf '%s\n' '{"jsonrpc":"2.0","id":3,"method":"resources/list"}' | python3 "$SERVER")"
  count="$(printf '%s\n' "$result" | python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d['result']['resources']))")"
  [ "$count" -eq 5 ]
}

# ---------------------------------------------------------------------------
# 11. cast_ask on db without record_fts degrades gracefully (no crash)
# ---------------------------------------------------------------------------
@test "cast_ask on empty db degrades gracefully" {
  _make_db  # builds tables WITHOUT record_fts
  req='{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"cast_ask","arguments":{"query":"test"}}}'
  result="$(printf '%s\n' "$req" | python3 "$SERVER")"
  # Must return valid JSON-RPC (not a crash), and indicate unavailability
  python3 -c "
import json, sys
d = json.loads('''$result''')
assert 'result' in d, f'expected result key, got: {d}'
r = d['result']
content_text = r['content'][0]['text']
assert r.get('isError') or 'full-text index unavailable' in content_text, \
    f'unexpected response: {content_text}'
"
}

# ---------------------------------------------------------------------------
# 12. cast-mcp status handshake OK with a real db
# ---------------------------------------------------------------------------
@test "cast-mcp status handshake OK with a real db" {
  _make_db
  run bash "$CLI" status
  [ "$status" -eq 0 ]
  [[ "$output" == *"handshake OK"* ]]
}

# ---------------------------------------------------------------------------
# 13–15. Shell syntax checks
# ---------------------------------------------------------------------------
@test "bin/cast-mcp passes bash -n" {
  run bash -n "$REPO_DIR/bin/cast-mcp"
  [ "$status" -eq 0 ]
}

@test "install.sh passes bash -n" {
  run bash -n "$REPO_DIR/install.sh"
  [ "$status" -eq 0 ]
}

@test "uninstall.sh passes bash -n" {
  run bash -n "$REPO_DIR/uninstall.sh"
  [ "$status" -eq 0 ]
}
