---
name: eow
description: "Build Rohan's end-of-week update: gather the week's real work across every repo, Linear, and Slack, then draft the team post and/or the manager DM. Use whenever asked for an EOW/weekly update, a recap of the week, what shipped, what he did this week, or a status update for a project or manager."
---

# eow

Two different artifacts come out of the same gathering pass. Know which one is
being asked for before drafting:

- **team update** — posted to a product channel (`#product-editor`). Covers
  *everyone's* work on the area, grouped by theme, with `s/o @person` credit.
- **manager DM** — what *Rohan specifically* did. First person, numbered,
  and it must include the work that leaves no trace in the product repos
  (infra, CI, Linear cleanup, incidents).

Never guess between them. If the ask is ambiguous ("eow update"), assume team
update and offer the DM after.

## Gather first, draft last

Do the whole gathering pass before writing a word. Half the value is the work
that isn't in the obvious repo.

### 1. Git — all repos, not just the product ones

Editor product: `mint` (frontend/dashboard), `server` (backend).
Everything else that counts as his week: `tesser`, `walgit`,
`infrastructure`, `eng-sandbox-infrastructure`, `devcloud`.

`~/Developer` is full of worktrees (`mint-*`, `server-*`, `*-wt`). Ignore them;
use the canonical checkout.

```sh
git -C <repo> fetch origin main -q
git -C <repo> log origin/main --since="<monday>" \
  --perl-regexp --author='^(?!Mintie Bot).*$' \
  --pretty=format:"%ad|%an|%s" --date=short
```

- **Always read `origin/main`, never `HEAD`.** His checkouts sit on feature
  branches constantly. `git -C <repo> rev-parse --abbrev-ref HEAD` first; if
  it isn't main, the local log contains unmerged WIP that must not be reported
  as shipped. Say explicitly what's still on a branch.
- **Filter out `Mintie Bot`** — `bump packages` commits are ~half of `mint`.
- **Squash-merge repo: there are no merge commits.** `--merges` returns
  nothing. One commit ≈ one PR, and `(#NNNN)` in the subject is the PR number.
- mint PRs are `#10xxx`/`#11xxx`, server PRs are `#79xx`/`#80xx`.

### 2. Reverts cancel out

Grep the week for `Revert`. A commit plus its revert is **net zero** — it did
not ship, and listing it is a lie of omission. Pair them by subject and drop
both, or say "landed and rolled back" if it matters.

### 3. Linear

Project: **Editor. Sisyphus** (`editor-sisyphus-dcc3f8fb91d2`), lead neha.

- `list_projects` with `includeMilestones` for milestone % — that's the
  headline number people quote.
- `list_issues` with `project` + `updatedAt` for the week's movement.
  It caps at 250 and paginates; the cursor is `endCursor` in the response.
  Large results get dumped to a file — parse with `python3`, don't re-read.
- Count the **cleanup**: issues moved to Canceled / Paused / Duplicate. That's
  invisible work he does deliberately and it belongs in the DM.
- Count **tickets created** — scoping a new milestone is real work.

**Milestone % undercounts the week.** It only tracks ticketed work, and whole
workstreams (Han's sidebar work, most of Rohan's infra) have no ticket. Never
present the % as the measure of what shipped; cross-check git against it and
say what shipped outside the milestone.

### 4. Slack — the only place incidents exist

Incidents leave no git trace tied to his name. Find them:

```
incident after:<monday>                       # finds #inc-* channels
from:<@U0B2MJ4H5KR> in:#inc-<channel>         # was he actually in it?
```

Channels are `#inc-p0-YYYY-MM-DD-slug`. Check **each one** for his messages —
being in the channel isn't the same as driving it. Look for: who ran the RCA,
who shipped a fix mid-incident, what the root cause was. This is the
highest-signal item in any manager DM and it's absent from every repo.

Also sweep his sent messages for the week — they surface work with no artifact:

```
from:<@U0B2MJ4H5KR> after:<monday> before:<date>   # 20/page, walk it back
```

His `:grass-block:` and `:bufo-ship:` posts are self-announced shipped work.

### 5. Reconcile

Before drafting, check the git list against Linear and Slack in both
directions. Things that hide:
- crash fixes (they read louder than anything else — always call one out)
- work credited to him in Linear but shipped by someone else, and vice versa
- infra PRs in `infrastructure` that enabled a product change
- unmerged branch work he's about to ship

## Voice

Lowercase, terse, no marketing. Fragments over sentences. His typos stay if
quoting him. Emoji carry meaning: `:sisyphus:` = the grind/stability,
`:bufo-ship:` = shipped, `:grass-block:` = a PR to review, `:nickstamp:` =
approve. Don't invent emoji placement; copy the pattern from his last update.

**Always `s/o @person` for reviews and for work he didn't do.** He does this in
every update and it's the main thing that makes the team post land well.

## Team update shape

```
Editor EOW update! linear board: <link>

Stability/bug fixes :sisyphus::
• <theme> (<specific>, <specific>, <specific>) (s/o @person)
• ...
Frontend Redesign :bufo-ship:: (s/o @person @person)
• <shipped surface>
• ...
next week: <2-3 words each>

cc @team
```

Group by theme, not by person or repo. Each bullet is a theme with the
specifics in parens — no PR numbers, no ticket IDs, they're noise in Slack.

## Manager DM shape

First person, numbered lists under bolded areas. Lead with a one-line frame if
the week was unusual. Link the team update rather than repeating it, then say
what *he* did. Sections that earn their place:

```
<frame line>

editor update here: <link to team post>. what i did:
1. <area>
...
e2e/ci work for editor stability:
1. ...
devboxes:
1. ...
incidents:
1. <#inc-channel> rca & fixed
2. <#inc-channel> fixed <specific bug>
```

Incidents go **last and get named with the channel link** — that's the part a
manager can verify at a glance.

## Don't

- Don't report branch commits as merged.
- Don't count a commit and its revert as two things.
- Don't quote a milestone % without saying what it misses.
- Don't pad with the adjacent workstreams (Mentha dashboard migration, client
  assistant UI, automations) when the ask is "the editor" — list them
  separately and let him cut.
- Don't invent incident details. If a search finds nothing, say so and ask.
