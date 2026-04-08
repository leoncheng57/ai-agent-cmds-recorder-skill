# ai-agent-cmds-recorder-skill

An agent skill that automatically records all terminal commands executed during AI coding sessions to a structured JSONL log file. Works with **Claude Code** and **OpenCode**.

## Why?

When AI coding agents execute shell commands, those commands don't appear in your normal shell history (`history` in zsh/bash). This makes it hard to:

- Review what the agent actually ran
- Re-run useful commands from past sessions
- Audit agent behavior
- Learn from command patterns
- Copy command sequences for documentation

Existing solutions are standalone CLI tools that parse conversation logs after the fact. They require separate installation, don't write local project files, and don't track sessions.

**This skill takes a different approach**: it's a pure agent skill (`SKILL.md`) that instructs the agent to record commands *as it runs them*, directly into your project directory. No external tools, no dependencies, no post-processing.

## Installation

Copy or clone this repo into any supported skill location:

```bash
# Global -- works in both Claude Code and OpenCode (recommended)
git clone https://github.com/leoncheng57/ai-agent-cmds-recorder-skill.git \
  ~/.agents/skills/ai-agent-cmds-recorder-skill

# OpenCode global
git clone https://github.com/leoncheng57/ai-agent-cmds-recorder-skill.git \
  ~/.config/opencode/skills/ai-agent-cmds-recorder-skill

# Claude Code global
git clone https://github.com/leoncheng57/ai-agent-cmds-recorder-skill.git \
  ~/.claude/skills/ai-agent-cmds-recorder-skill

# Project-local (OpenCode)
git clone https://github.com/leoncheng57/ai-agent-cmds-recorder-skill.git \
  .opencode/skills/ai-agent-cmds-recorder-skill

# Project-local (Claude Code)
git clone https://github.com/leoncheng57/ai-agent-cmds-recorder-skill.git \
  .claude/skills/ai-agent-cmds-recorder-skill
```

Then add `.agent-cmd-history.jsonl` to your project's `.gitignore`.

## How It Works

The skill is a single `SKILL.md` file containing instructions the agent follows using its built-in tools. No scripts, no runtime dependencies.

**Three phases:**

1. **Session Initialization** -- The agent generates a unique session ID, detects which agent it is, and sets up the log file path.

2. **Command Recording** -- After every Bash command, the agent appends a JSONL entry to `.agent-cmd-history.jsonl` with the command, timestamp, exit code, working directory, session ID, and agent type.

3. **Session Summary** -- At session end (or on request), the agent prints a summary of commands run, succeeded, and failed.

## Output Format

Each line in `.agent-cmd-history.jsonl` is a JSON object:

```json
{"timestamp":"2026-04-08T14:30:02Z","cmd":"git status","cwd":"/Users/dev/projects/my-app","exit":0,"session":"2026-04-08-a3f2","agent":"opencode"}
```

| Field       | Type   | Required | Description                                  |
|-------------|--------|----------|----------------------------------------------|
| `timestamp` | string | yes      | ISO 8601 UTC timestamp of command execution  |
| `cmd`       | string | yes      | The full command string as executed           |
| `cwd`       | string | yes      | Working directory at time of execution        |
| `exit`      | number | no       | Exit code. Null/omitted if unknown           |
| `session`   | string | yes      | Unique session ID (date + random hex suffix) |
| `agent`     | string | yes      | `"opencode"`, `"claude-code"`, or `"unknown"`|

See [`examples/sample-output.jsonl`](examples/sample-output.jsonl) for a full example.

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

| Agent       | Supported | Skill Locations                                                        |
|-------------|-----------|------------------------------------------------------------------------|
| OpenCode    | Yes       | `.opencode/skills/`, `~/.config/opencode/skills/`, `~/.agents/skills/` |
| Claude Code | Yes       | `.claude/skills/`, `~/.claude/skills/`, `~/.agents/skills/`            |

Any agent that supports the `SKILL.md` format with YAML frontmatter should work.

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
