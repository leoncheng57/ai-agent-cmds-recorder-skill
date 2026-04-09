# ai-agent-cmds-recorder-skill

[![GitHub release](https://img.shields.io/github/v/release/leoncheng57/ai-agent-cmds-recorder-skill)](https://github.com/leoncheng57/ai-agent-cmds-recorder-skill/releases)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

An agent skill that automatically records all terminal commands executed during AI coding sessions to a structured JSONL log file. Works with **Claude Code**, **OpenCode**, **Codex**, **Gemini CLI**, and **Cursor**.

## Why?

When AI coding agents execute shell commands, those commands don't appear in your normal shell history (`history` in zsh/bash). This makes it hard to:

- Review what the agent actually ran
- Re-run useful commands from past sessions
- Audit agent behavior
- Learn from command patterns
- Copy command sequences for documentation

Existing solutions are standalone CLI tools that parse conversation logs after the fact. They require separate installation, don't write local project files, and don't track sessions.

**This skill takes a different approach**: it's an agent skill (`SKILL.md`) that instructs the agent to record commands *as it runs them*, directly into your project directory. Bundled shell scripts let you query the log — list commands from a session, view all sessions, and more. No external tools, no runtime dependencies beyond `jq`.

## Installation

This skill follows the [Agent Skills open standard](https://agentskills.io) (`SKILL.md` with YAML frontmatter). The universal install path works across most agents:

```bash
# Universal -- works with OpenCode, Codex, Gemini CLI, and Claude Code
git clone https://github.com/leoncheng57/ai-agent-cmds-recorder-skill.git \
  ~/.agents/skills/ai-agent-cmds-recorder-skill
```

Then add `.agent-cmd-history.jsonl` to your project's `.gitignore`.

### Agent-specific installation

<details>
<summary><strong>OpenCode</strong></summary>

```bash
# Global (any of these work)
git clone https://github.com/leoncheng57/ai-agent-cmds-recorder-skill.git \
  ~/.agents/skills/ai-agent-cmds-recorder-skill
# or
git clone https://github.com/leoncheng57/ai-agent-cmds-recorder-skill.git \
  ~/.config/opencode/skills/ai-agent-cmds-recorder-skill

# Project-local
git clone https://github.com/leoncheng57/ai-agent-cmds-recorder-skill.git \
  .opencode/skills/ai-agent-cmds-recorder-skill
```

OpenCode discovers `SKILL.md` files automatically and shows them in the available skills list. The agent loads the full skill on demand when it matches the description.

</details>

<details>
<summary><strong>Claude Code</strong></summary>

```bash
# Global (any of these work)
git clone https://github.com/leoncheng57/ai-agent-cmds-recorder-skill.git \
  ~/.agents/skills/ai-agent-cmds-recorder-skill
# or
git clone https://github.com/leoncheng57/ai-agent-cmds-recorder-skill.git \
  ~/.claude/skills/ai-agent-cmds-recorder-skill

# Project-local
git clone https://github.com/leoncheng57/ai-agent-cmds-recorder-skill.git \
  .claude/skills/ai-agent-cmds-recorder-skill
```

Claude Code discovers skills via the `/skill` command and loads them on demand.

</details>

<details>
<summary><strong>OpenAI Codex</strong></summary>

```bash
# Global
git clone https://github.com/leoncheng57/ai-agent-cmds-recorder-skill.git \
  ~/.agents/skills/ai-agent-cmds-recorder-skill

# Project-local
git clone https://github.com/leoncheng57/ai-agent-cmds-recorder-skill.git \
  .agents/skills/ai-agent-cmds-recorder-skill
```

Codex discovers `SKILL.md` files in `.agents/skills/` directories from the repo root up to your working directory, plus the global `~/.agents/skills/` path.

</details>

<details>
<summary><strong>Google Gemini CLI</strong></summary>

```bash
# Global (any of these work)
git clone https://github.com/leoncheng57/ai-agent-cmds-recorder-skill.git \
  ~/.agents/skills/ai-agent-cmds-recorder-skill
# or
git clone https://github.com/leoncheng57/ai-agent-cmds-recorder-skill.git \
  ~/.gemini/skills/ai-agent-cmds-recorder-skill

# Project-local
git clone https://github.com/leoncheng57/ai-agent-cmds-recorder-skill.git \
  .gemini/skills/ai-agent-cmds-recorder-skill
# or
git clone https://github.com/leoncheng57/ai-agent-cmds-recorder-skill.git \
  .agents/skills/ai-agent-cmds-recorder-skill
```

Gemini CLI discovers skills at session start and activates them on demand via the `activate_skill` tool.

</details>

<details>
<summary><strong>Cursor</strong></summary>

Cursor uses its own `.mdc` rule format instead of the Agent Skills standard. To use this skill in Cursor, copy the SKILL.md content into a Cursor rule:

```bash
mkdir -p .cursor/rules
```

Create `.cursor/rules/ai-agent-cmds-recorder.mdc`:

```
---
description: Use when starting any coding session to automatically record all terminal commands to a structured JSONL log file.
alwaysApply: true
---

# AI Agent Command Recorder
<!-- Copy the content of SKILL.md here (everything after the frontmatter) -->
```

Alternatively, you can reference the SKILL.md content manually by pasting it into Cursor's rule file. See [Cursor Rules docs](https://docs.cursor.com/context/rules) for details.

</details>

## How It Works

The skill is a `SKILL.md` file containing instructions the agent follows using its built-in tools, plus bundled shell scripts for querying the log.

**Three phases:**

1. **Session Initialization** -- The agent generates a unique session ID, detects which agent it is, and sets up the log file path.

2. **Command Recording** -- After every Bash command, the agent appends a JSONL entry to `.agent-cmd-history.jsonl` with the command, timestamp, exit code, working directory, session ID, and agent type.

3. **Session Summary** -- At session end (or on request), the agent prints a summary of commands run, succeeded, and failed.

**Bundled commands** in `bin/` let you (or the agent) query the log file directly — list commands from a session, view all recorded sessions, etc.

## Output Format

Each line in `.agent-cmd-history.jsonl` is a JSON object:

```json
{"cmd":"git status","cwd":"/Users/dev/projects/my-app","exit":0,"timestamp":"2026-04-08T14:30:02Z","session":"2026-04-08-a3f2","agent":"opencode"}
```

| Field       | Type   | Required | Description                                  |
|-------------|--------|----------|----------------------------------------------|
| `cmd`       | string | yes      | The full command string as executed           |
| `cwd`       | string | yes      | Working directory at time of execution        |
| `exit`      | number | no       | Exit code. Null/omitted if unknown           |
| `timestamp` | string | yes      | ISO 8601 UTC timestamp of command execution  |
| `session`   | string | yes      | Unique session ID (date + random hex suffix) |
| `agent`     | string | yes      | `"opencode"`, `"claude-code"`, or `"unknown"`|

See [`examples/sample-output.jsonl`](examples/sample-output.jsonl) for a full example.

## Bundled Commands

The `bin/` directory includes shell scripts for querying the log file. Both require [`jq`](https://jqlang.github.io/jq/).

### List commands from a session

```bash
# List all commands from a specific session
bash bin/list-commands.sh <session-id> .agent-cmd-history.jsonl
```

Output:

```
    1  [2026-04-08T14:30:02Z] [exit 0] git status
      cwd: /Users/dev/projects/my-app
    2  [2026-04-08T14:30:15Z] [exit 0] npm install express
      cwd: /Users/dev/projects/my-app
    3  [2026-04-08T14:30:48Z] [exit 1] npm run build
      cwd: /Users/dev/projects/my-app

Total: 3 command(s) in session 2026-04-08-a3f2
```

### List all sessions

```bash
# List all recorded sessions with metadata
bash bin/list-sessions.sh .agent-cmd-history.jsonl
```

Output:

```
Sessions in .agent-cmd-history.jsonl:

  SESSION ID                AGENT             CMDS  TIME RANGE
  ----------                -----             ----  ----------
  2026-04-08-a3f2           opencode            10  2026-04-08T14:30:02Z → 2026-04-08T14:32:58Z

Total: 1 session(s)
```

Both scripts default to `.agent-cmd-history.jsonl` in the current directory if the log file path is omitted.

## Testing Locally

You can test the bundled scripts against the included sample data:

```bash
# Clone the repo
git clone https://github.com/leoncheng57/ai-agent-cmds-recorder-skill.git
cd ai-agent-cmds-recorder-skill

# Test list-sessions against the sample log
bash bin/list-sessions.sh examples/sample-output.jsonl

# Test list-commands for a specific session
bash bin/list-commands.sh 2026-04-08-a3f2 examples/sample-output.jsonl
```

To test the full skill (recording + querying) end-to-end:

1. Install the skill into your agent (see [Installation](#installation))
2. Start a new agent session and activate the skill
3. Run a few commands — the agent should append entries to `.agent-cmd-history.jsonl`
4. Ask the agent to "list commands" or "show sessions" — it should run the bundled scripts
5. Verify the log file manually: `cat .agent-cmd-history.jsonl | jq .`

## Working With the Log

The JSONL format works well with standard Unix tools and `jq`:

```bash
# View all commands from a specific session
cat .agent-cmd-history.jsonl | jq -r 'select(.session=="2026-04-08-a3f2") | .cmd'

# Count commands per session
cat .agent-cmd-history.jsonl | jq -r '.session' | sort | uniq -c

# Find all failed commands
cat .agent-cmd-history.jsonl | jq 'select(.exit != 0)'

# Commands from today
cat .agent-cmd-history.jsonl | jq 'select(.timestamp | startswith("2026-04-08"))'

# List unique commands across all sessions
cat .agent-cmd-history.jsonl | jq -r '.cmd' | sort -u
```

## Compatibility

| Agent         | Native Support | Install Path                                                           |
|---------------|----------------|------------------------------------------------------------------------|
| OpenCode      | Yes            | `.opencode/skills/`, `~/.config/opencode/skills/`, `~/.agents/skills/` |
| Claude Code   | Yes            | `.claude/skills/`, `~/.claude/skills/`, `~/.agents/skills/`            |
| OpenAI Codex  | Yes            | `.agents/skills/`, `~/.agents/skills/`                                 |
| Gemini CLI    | Yes            | `.gemini/skills/`, `~/.gemini/skills/`, `~/.agents/skills/`            |
| Cursor        | Manual         | `.cursor/rules/*.mdc` (requires converting to Cursor rule format)      |

All agents that support the [Agent Skills open standard](https://agentskills.io) (`SKILL.md` with YAML frontmatter) work natively. Cursor requires manual conversion to its `.mdc` rule format.

## Contributing

This project uses [Conventional Commits](https://www.conventionalcommits.org/) enforced by commitlint and Husky.

**Release-triggering commit types:**
- `feat:` -> minor release
- `fix:` -> patch release
- `!` suffix or `BREAKING CHANGE:` -> major release

**Non-release commit types:** `docs:`, `chore:`, `refactor:`, `test:`, `style:`, `ci:`, `build:`

Releases are automated via [semantic-release](https://github.com/semantic-release/semantic-release) on pushes to `main`.

## License

[MIT](LICENSE)
