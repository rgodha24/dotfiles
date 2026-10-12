---
name: tesser-cli
description: Run dev servers, tests, typechecks, and builds on persistent cloud boxes while the code stays local. Use when the user wants a dev server running off the laptop with localhost as the window into it, several worktrees running at once, a box for tests or heavy commands, or when the repo has a devboxes or tesser skill under .claude/skills or .agents/skills.
---

First look for the repo's own skill: a SKILL.md and *.toml manifests in any of
.claude/skills/devboxes, .claude/skills/tesser, .agents/skills/devboxes,
.agents/skills/tesser at the repo root. Check all four; what you find there wins.

tesser explains itself. Before your first command:

    tesser --help          how it works, and the rules
    tesser <cmd> --help    what that command actually does

Errors name the next command to run. Trust them over anything you remember.
