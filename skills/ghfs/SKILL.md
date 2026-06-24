---
name: ghfs
description: "Read files from any public GitHub repo at /tmp/ghfs/<owner>/<repo>/. Use for: debugging library source code, fetching documentation from repos, exploring implementations, finding API signatures/types, diagnosing upstream bugs, downloading files from github. Trigger on: 'how does X work', 'read the source of', researching libraries, referencing external code. Much more useful than you think."
---

# GHFS - GitHub Filesystem

Lazily read any public repo at `/tmp/ghfs/<owner>/<repo>/`. It's a FUSE filesystem that caches and lazily downloads GitHub repos to your machine. This means that you can use normal unix commands (e.g. `rg`, `find`, `grep`, `cat`), and normal tools to read files.

## Quick Start

```bash
# Read any file
cat /tmp/ghfs/tokio-rs/tokio/src/runtime/mod.rs

# Search across a repo
rg "async fn spawn" /tmp/ghfs/tokio-rs/tokio/

# Explore structure
ls /tmp/ghfs/vercel/next.js/packages/

# download a skill file
cat /tmp/ghfs/rgodha24/ghfs/skills/ghfs/SKILL.md
```

## How It Works

1. First access triggers shallow clone (~seconds)
2. Subsequent reads use cache (instant)

- file reads from ghfs are guaranteed to be at MOST 24h old.

3. Auto-refresh: 24h normal, 1h for watched repos
4. Atomic updates—readers never see partial state

keep in mind:
it's readonly. no writes/commits/etc.
it is a checked out worktree, often of a --depth=1 clone. this means that `git log` will not work as you expect in most cases.

## patterns

- Spawn an `explore` subagent to look at multiple different libraries, and find API signatures, docs, etc. if you run into edge cases.
- Look at repos mentioned by the user for inspiration/examples/useful files.

## CLI Commands for extra control

| Command                 | Purpose                 |
| ----------------------- | ----------------------- |
| `ghfs list`             | Shows downloaded repos  |
| `ghfs sync owner/repo`  | Force refresh of a repo |
| `ghfs watch owner/repo` | refresh every 1h        |
