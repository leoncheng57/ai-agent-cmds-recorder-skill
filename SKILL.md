---
name: ai-agent-cmds-recorder-skill
description: Use when starting any coding session to automatically record all terminal commands and MCP tool calls to a structured JSONL log file. Always-on command history for AI agent sessions.
---

# AI Agent Command Recorder

Automatically record every Bash/terminal command and MCP tool call you execute during a session to a structured JSONL log file in the project directory. Recording is instruction-driven -- you use your built-in file tools to append entries. Bundled shell scripts provide querying commands.

## Session Initialization

At the **start of every session**, do the following:

1. **Generate a session ID** by running:
   ```bash
   echo "$(date -u +%Y-%m-%d)-$(head -c 4 /dev/urandom | xxd -p | head -c 4)"
   ```
   Store the output (e.g., `2026-04-08-a3f2`) as your session ID for the rest of this session.

2. **Detect agent type**: Identify yourself as `"opencode"`, `"claude-code"`, or `"unknown"`.

3. **Set the log file path**: `.agent-cmd-history.jsonl` in the project/workspace root directory.

4. **Check .gitignore**: If `.agent-cmd-history.jsonl` is NOT listed in the project's `.gitignore`, suggest to the user that they add it.

**IMPORTANT:** The session ID generation command above is the ONLY Bash command during initialization that you do NOT need to record.

## Bash Command Recording

**After EVERY Bash tool invocation**, immediately append one JSONL entry to `.agent-cmd-history.jsonl`.

For each command, capture:
- `type` -- always `"bash"`
- `cmd` -- the full command string as executed
- `cwd` -- working directory at time of execution
- `exit` -- exit code (0 = success, non-zero = failure, null if unknown)
- `timestamp` -- current UTC time in ISO 8601 format
- `session` -- the session ID generated during initialization
- `agent` -- the agent type detected during initialization

**Append using:**
```bash
echo '{"type":"bash","cmd":"<command>","cwd":"<dir>","exit":<code>,"timestamp":"<ISO8601>","session":"<id>","agent":"<type>"}' >> .agent-cmd-history.jsonl
```

## MCP Tool Call Recording

**After EVERY MCP tool invocation**, immediately append one JSONL entry to `.agent-cmd-history.jsonl`.

MCP tools include any tool provided by an MCP server -- for example Grafana tools (`grafana_query_loki_logs`, `grafana_search_dashboards`), Atlassian tools (`atlassian_searchJiraIssuesUsingJql`, `atlassian_getConfluencePage`), Notion tools, Backstage tools, etc.

For each MCP tool call, capture:
- `type` -- always `"mcp"`
- `tool` -- the tool name as invoked (e.g., `grafana_query_loki_logs`)
- `params` -- an array of the **parameter keys only** (not values). For example, if you called `grafana_query_loki_logs` with `datasourceUid`, `logql`, and `startRfc3339`, record `["datasourceUid","logql","startRfc3339"]`
- `timestamp` -- current UTC time in ISO 8601 format
- `session` -- the session ID generated during initialization
- `agent` -- the agent type detected during initialization

**Append using:**
```bash
echo '{"type":"mcp","tool":"<tool_name>","params":["<key1>","<key2>"],"timestamp":"<ISO8601>","session":"<id>","agent":"<type>"}' >> .agent-cmd-history.jsonl
```

**Do NOT record MCP results/responses** -- only the tool name and parameter keys.

## Recording Rules

- **DO** record every Bash command you execute via the Bash tool
- **DO** record every MCP tool call (Grafana, Atlassian, Notion, Backstage, etc.)
- **DO NOT** record the `echo '...' >> .agent-cmd-history.jsonl` append commands themselves
- **DO NOT** record file reads, edits, grep, glob, or Task/subagent operations (these are built-in agent tools, not MCP tools)
- **DO NOT** pretty-print the JSON -- one compact object per line
- **NEVER** overwrite the file -- always append (`>>`)

## Session Summary

When the **session ends** or the user asks to **"show commands"** / **"list commands"**:

1. Count total entries, bash commands (with successes/failures), and MCP calls for the current session
2. Print a brief summary:
   ```
   Session <session-id>: <total> entries (<bash_count> bash, <mcp_count> mcp)
   Bash: <succeeded> succeeded, <failed> failed
   Log: .agent-cmd-history.jsonl
   ```

## Bundled Commands

This skill includes shell scripts in `bin/` for querying the log file. Resolve the skill's install directory and run them from there. Both require `jq`.

### List Commands for Current Session

When the user asks to **"list commands"**, **"show history"**, or **"what commands did you run"**, run:

```bash
bash <SKILL_DIR>/bin/list-commands.sh <SESSION_ID> .agent-cmd-history.jsonl
```

Replace `<SKILL_DIR>` with the absolute path to this skill's directory and `<SESSION_ID>` with the current session ID.

This prints every command from the session with its sequence number, timestamp, exit code, and working directory.

### List All Sessions

When the user asks to **"list sessions"**, **"show sessions"**, or **"what sessions are recorded"**, run:

```bash
bash <SKILL_DIR>/bin/list-sessions.sh .agent-cmd-history.jsonl
```

This prints a table of all session IDs with their agent type, command count, and time range.

## JSONL Schema Reference

### Common fields (all entries)

| Field       | Type   | Required | Description                                        |
|-------------|--------|----------|----------------------------------------------------|
| `type`      | string | yes      | Entry type: `"bash"` or `"mcp"`                    |
| `timestamp` | string | yes      | ISO 8601 UTC timestamp                             |
| `session`   | string | yes      | Unique session ID (date + random hex suffix)       |
| `agent`     | string | yes      | `"opencode"`, `"claude-code"`, or `"unknown"`      |

### Bash-specific fields (type = "bash")

| Field       | Type   | Required | Description                                  |
|-------------|--------|----------|----------------------------------------------|
| `cmd`       | string | yes      | The full command string as executed           |
| `cwd`       | string | yes      | Working directory at time of execution        |
| `exit`      | number | no       | Exit code. Null/omitted if unknown           |

### MCP-specific fields (type = "mcp")

| Field       | Type     | Required | Description                                  |
|-------------|----------|----------|----------------------------------------------|
| `tool`      | string   | yes      | MCP tool name (e.g., `grafana_query_loki_logs`) |
| `params`    | string[] | yes      | Parameter keys only (no values)              |
