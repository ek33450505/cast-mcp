## Description

<!-- What does this PR change and why? -->

## Checklist

- [ ] `bash install.sh && bash uninstall.sh` round-trip clean
- [ ] BATS tests pass: `bats tests/`
- [ ] `bash -n bin/cast-mcp install.sh uninstall.sh` — all syntax-check
- [ ] `cast-mcp --quick` and `cast-mcp --json` both work
- [ ] No writes to disk anywhere — cast-mcp is strictly read-only
- [ ] No hardcoded paths — `$HOME` / `~/` used
- [ ] `CHANGELOG.md` updated for user-visible changes
