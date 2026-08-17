---
name: ghfs
description: "Read files from any public GitHub repo at (Linux: /mnt/github/<owner>/<repo>, macOS: /tmp/ghfs/<owner>/<repo>). Use to get library docs/source code whenever you have a question about it, finding api signatures, researching implementation strategies, finding code to reuse, etc. If you are considering whether you need it or not, the answer should basically always be a yes."
---

# GHFS - GitHub Filesystem

Lazily read any public repo via a FUSE filesystem that caches and lazily downloads GitHub repos to your machine. Use normal unix commands (`rg`, `find`, `grep`, `cat`) and normal tools to read files.

## Mount point

| Platform | Mount         |
| -------- | ------------- |
| Linux    | `/mnt/github` |
| macOS    | `/tmp/ghfs`   |

```bash
# prints the real mount in use
ghfs status | grep -i mount
```

the below uses linux syntaxes, but works on everything.

## Quick Start

```bash
# Read any file (default branch / HEAD)
cat /mnt/github/tokio-rs/tokio/src/runtime/mod.rs

# Search across a repo
rg "async fn spawn" /mnt/github/tokio-rs/tokio/

# Explore structure
ls /mnt/github/vercel/next.js/packages/

# download a skill file at a certain version
cat /mnt/github/rgodha24/ghfs/skills/ghfs/SKILL.md
```

## Reading a specific branch, tag, or commit (`/by-ref`)

Besides the default-branch alias `/<owner>/<repo>/...`, ghfs exposes a
parallel root that pins an exact ref:

```text
/by-ref/<owner>/<repo>/<encoded-ref>/...   # branch | tag | commit OID
```

`<ref>` is a _single_ path component, so any `/` inside a ref name is
percent-encoded as `%2F` (and literal `%` as `%25`). Plain names like `main`,
`v1.2.0`, or a hex commit OID pass through unchanged.

```bash
# a feature branch with a slash in its name
ls /mnt/github/by-ref/tokio-rs/tokio/feature%2Fnew-cache/src/

# a tag
cat /mnt/github/by-ref/vercel/next.js/v15.0.0/package.json

# a full ref path (slashes encoded)
rg "tokio::spawn" /mnt/github/by-ref/tokio-rs/tokio/refs%2Fheads%2Fnext/

# a specific commit OID (abbreviated hex allowed, >= 7 chars)
cat /mnt/github/by-ref/tokio-rs/tokio/abc1234/src/lib.rs

# list which branches/tags exist for a repo
ls /mnt/github/by-ref/tokio-rs/tokio/
```

Resolution order ghfs uses for `<ref>`:

1. `HEAD` or a full ref path (`refs/heads/...`, `refs/tags/...`) matches
   verbatim.
2. A pure-hex string (>= 7 chars) resolves to a commit object directly
   (abbreviation allowed).
3. Otherwise it's treated as a **short** branch or tag name; if both a
   branch and a tag share the name, ghfs surfaces an ambiguous-ref error
   rather than silently picking one.

Revspec expressions (`HEAD~3`, `main^`, `abc...def`) are **not** supported.

An owner literally named `by-ref` is still reachable as
`/by-ref/by-ref/...` — `by-ref` is only reserved as the _first_ path
component.

## How It Works

1. First access triggers shallow clone (~seconds)
2. Subsequent reads use cache (instant)
   - file reads from ghfs are guaranteed to be at MOST 24h old.
3. Auto-refresh: 24h normal, 1h for watched repos
4. Atomic updates—readers never see partial state

keep in mind:
it's readonly. no writes/commits/etc.
it is a checked out worktree, often of a `--depth=1` clone. this means that `git log`
will not work as you expect in most cases.

## patterns

- Spawn an `explore` subagent to look at multiple different libraries, and find API
  signatures, docs, etc. if you run into edge cases.
- Look at repos mentioned by the user for inspiration/examples/useful files.

## CLI Commands for extra control

| Command                 | Purpose                                      |
| ----------------------- | -------------------------------------------- |
| `ghfs status`           | Show daemon status + cached repos            |
| `ghfs sync owner/repo`  | Force re-sync a repository                   |
| `ghfs gc`               | Garbage-collect cache metadata / stale state |
| `ghfs doctor`           | Check dependencies                           |
| `ghfs service <action>` | Install/manage the foreground service        |

