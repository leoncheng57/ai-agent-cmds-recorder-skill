---
name: ai-agent-cmds-recorder-skill
description: Use when starting any coding session to automatically record all terminal commands to a structured JSONL log file. Always-on command history for AI agent sessions.
---

# AI Agent Command Recorder

Automatically record every Bash/terminal command you execute during a session to a structured JSONL log file in the project directory. This is a pure-instruction skill -- no scripts, no dependencies. You use your built-in file tools to append entries.

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

## Command Recording

**After EVERY Bash tool invocation**, immediately append one JSONL entry to `.agent-cmd-history.jsonl`.

For each command, capture:
- `timestamp` -- current UTC time in ISO 8601 format
- `cmd` -- the full command string as executed
- `cwd` -- working directory at time of execution
- `exit` -- exit code (0 = success, non-zero = failure, null if unknown)
- `session` -- the session ID generated during initialization
- `agent` -- the agent type detected during initialization

**Append using:**
```bash
echo '{"timestamp":"<ISO8601>","cmd":"<command>","cwd":"<dir>","exit":<code>,"session":"<id>","agent":"<type>"}' >> .agent-cmd-history.jsonl
```

### Recording Rules

- **DO** record every Bash command you execute via the Bash tool
- **DO NOT** record the `echo '...' >> .agent-cmd-history.jsonl` append commands themselves
- **DO NOT** record file reads, edits, grep, glob, or Task/subagent operations
- **DO NOT** pretty-print the JSON -- one compact object per line
- **NEVER** overwrite the file -- always append (`>>`)

## Session Summary

When the **session ends** or the user asks to **"show commands"** / **"list commands"**:

1. Count total commands, successes (exit 0), and failures (exit != 0) for the current session
2. Print a brief summary:
   ```
   Session <session-id>: <total> commands (<succeeded> succeeded, <failed> failed)
   Log: .agent-cmd-history.jsonl
   ```

## JSONL Schema Reference

| Field       | Type   | Required | Description                                  |
|-------------|--------|----------|----------------------------------------------|
| `timestamp` | string | yes      | ISO 8601 UTC timestamp of command execution  |
| `cmd`       | string | yes      | The full command string as executed           |
| `cwd`       | string | yes      | Working directory at time of execution        |
| `exit`      | number | no       | Exit code. Null/omitted if unknown           |
| `session`   | string | yes      | Unique session ID (date + random hex suffix) |
| `agent`     | string | yes      | `"opencode"`, `"claude-code"`, or `"unknown"`|
