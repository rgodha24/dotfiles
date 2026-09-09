# Rohan's voice, from his own PRs

Read this to calibrate a title, or when he explicitly asks you to draft his
part of the body. Everything here is verbatim from PRs he authored in
mintlify/mint and mintlify/server (branches under `rohan/`; not the
devin/codex/opencode/claude-authored ones).

## Titles

```
fix(editor): gitlab git push bugs
feat(editor): support GitLab pushes to branches v2
feat(admin-mcp): fall back to reading by pageId in `read`
fix(git): preserve http when building the GHES url
fix(git proxy): passthrough committedAt to fix editor
fix: stop throwing on mintlify.site revalidations
feat: support *.mintlifysite.com
fix(editor): stop invalidating unloaded hp documents
chore(editor): log invalid ydocs in onLoadDocument
fix(editor): fix docs.json duplication with trailing slashes
fix(editor): make branches v2 discard use merge base sha
chore(editor): stop hashing non-mdx files through the mdx parser
chore(editor): log nav write failures
chore: increase email signin rate limit in dev
feat(editor): skip inbound sync for branches with no editor metadata
feat(editor): sync external pushes to editor branches into hocuspocus
feat(editor): bring back autocommits!
chore: only listen to sqs webhooks for configured git repos in dev
perf(editor): fire and forget push to docs json
chore: drop subdomain from origin request for dd costs
feat(auth): redirect preview handshakes back to the requested host
feat(auth): allow editor preview handshakes on any auth type
chore: bump packages
feat(editor): coalesce concurrent navWriter mutates per room
feat(editor): backfill file node frontmatter script
fix(docs-proxy): stop caching live preview alongside normal pages
feat(editor): give editor agent read-only access to code repos
feat(editor): review flow
perf(editorFs): pool & reuse hocuspocus connections
feat(editor): new monotonic editorMetadata revision counter
feat(editorAgent): use chroma `search` for large file searches
perf(editor): faster editor fs file reads
perf(editor): faster modified pendingActions calculations
feat(editor): --meta flag for editor agent ls/cat
chore(editor): rm dual write for navtree migration
feat(editor-drafts): rewrite the autocommit & discard backend
feat(editor): show git-only branches in the branch dropdown
fix(editor): live preview for pages not in navigation
chore(editor): remove the single dollar math text option
fix(editor): make optimistic saving rows match server
fix(editor): stop double url encoding branch
refactor(editor): render navtree as one virtualized list
feat(editor): leave private pages
fix(editor): stop executing javascript in MDX
chore(editor): delete some e2e tests
chore(editor): rm monaco!
feat(editor): resolve frontmatter from yjs for instant updates
feat(live preview): more caching & observability
fix(editor): colspan tables parsing
fix(editor): support mdx syntax inside links
fix(editor): coalesce suggestion edits
perf(editor): rm .findOne() query & btree indices
fix(live preview): reuse preview cache outside of new onboarding
fix(editor): delete frontmatter key on removal
fix(editor): multiple roundtrip bugs for marqeta
fix(editor): wrap children of single line components
fix(editor): insert media into tables correctly
feat(editor): skeleton for media uploads
perf(editor): dedupe in flight editor media requests
feat(editor): optimistic branches v2 creation
feat(editor): branch creation dock
test(editor): run e2e against branches v2
chore(editor): pass in parentBranch to backend
feat(editor): restore editor breadcrumbs in the topbar
chore(editor): fix horizontal bug with large text
feat(editor): reconnect GitHub flow for SAML SSO failures
feat(branches v2): optimistic branch creation
feat(editor): surface saml/ip allowlist errors
feat(dashboard): enable dashboard devtools in e2e tests
chore(editor): delete dead parts of draft
fix(editor): stop throwing for notfound icons
feat(editor): open agent in live preview
feat(editor): open sitesettings in live preview
chore(editor): open newtab live previews in new editor tab
feat(editor): better skeleton state
feat(editor): authenticated live previews!
feat(editor): branches dropdown v2
feat(editor): reuse cached deployed pages for live preview
fix(client): allow dashboard frame ancestors on auth-enabled sites
chore(client): dont send analytics while embedded in editor
feat(client): postMessage to activate live-preview mode
fix(validation): group schema parsing exponential time complexity
fix(editor): remove the localstorage of frontmatters
fix(editor): hocuspocus refcount bug
fix(editor): backspace behavior on bullets
fix(editor): batch tanstack db transactions
feat(editor): live previews v2
feat(review flow): show ui in more states
fix(review flow): unbreak for drafts
feat(editor agent): render clone_repo and repo_bash tools
feat(cli): mint format command with bundled editor converter
feat(cli): hidden mint format command
fix(editor): roundtrip latex math equations correctly
chore(editor): rm the draft announcement card
feat(editor): move the agent to the right
fix(editor agent): bugs in auto resume
feat(editor): top level page comments
chore(editor): navtree border nit
chore(editor): navtree debug view
feat(editor): han ui/ux nits
chore(editor agent): copy updates
fix(editor): stop dual highlighting root nodes
feat(api playground): set local base url overrides
```

Pattern: type + product-area scope, then a short noun phrase or blunt verb
phrase. Lowercase throughout except proper nouns and identifiers. Ticket ids
never appear. Length rarely passes 7 words after the colon.

## His part of the body

These samples still carry the old `## Summary` / `## Test Plan` scaffold
because that's what the template gave him. The skill now drops that
scaffold: his words go in bare, and the test plan is written under
`# clank`. Read these for tone only.

Short. Lowercase. Contractions without apostrophes (`doesnt`, `dont`,
`thats`, `isnt`, `didnt`, `its`). Slang and abbreviations: `basically`,
`abt`, `bc`, `r` (are), `lwk`, `p` (pretty), `rn`, `idk`, `lol`, `ig`,
`eg`/`e.g.`, `tho`, `chill`, `grass`, `nit`, `stamp`. CAPS for emphasis
(`NOT`, `MAKE SURE`, `READS THE ENTIRE NAVTREE`). `^^` to refer to the
thing above. Typos left in. Numbered lists for scenarios. Links pasted bare
(slack threads, datadog log queries, linear, unleash flags, other-repo PRs,
kb.mintlify.com specs). Customer names as motivation (`for marqeta`,
`should fix xbox`, `fixes ocient`, `autumn wanted this`).

Samples:

```
## Summary
title and also we only write to tanstack db if the revision we are writing is higher than the one we have applied already

should fix xbox

.findOne for some reason READS THE ENTIRE NAVTREE
## Test Plan
all good
```

```
## Summary
we literally just used it for `<iframe>`. just use a textarea for it
## Test Plan
```

```
## Summary
basically before we used to set frontmatter.`groups` to undefined when we deleted everything. this caused issues

instead, we just delete the `groups` key entirely, using Reflect.
## Test Plan
unit tests!
```

```
## summary

we get editor media from git. we refetched this a LOT in parallel on routes like live preview, which caused github ratelimits.

this fixes it by reusuing react querys in flight request coalescing to make sure we are only doing 1 req at a time!
## test plan

make sure live preview and editor media arent broken. they wont be tho this is p simple.
# clank
…
```

```
## Summary
in this case:

1. user is on branch A
2. user makes changes on branch A and then they get autocommitted (say to sha H)
3. user creates branch B off of branch A (which obviously brings over the commits)
4. user tries to discard the change on branch B.

the user can not discard the committed change because:
- old code would reset to commit sha H
- new code resets to `main`.

## Test Plan
test the above! proof it works:

- https://github.com/mintlify-community/docs-rohantestneworg-5cb8b1a0/pull/8 (was created based off of below and then discarded)
- https://github.com/mintlify-community/docs-rohantestneworg-5cb8b1a0/pull/7
```

```
## Summary
ok so basically

thinking behind this was that if there are no listeners, instead of running our own gitsync, we just invalidate the document and then fix merge conflicts on next onLoadDocument call

BUT

the no listeners field is based on a random hocuspocus server's connections so its wrong a lot.

this is specifically a problem now, because it causes comments to get disconnected from their source threads & because we are autocommitting a lot. should fix a kabaji issue
## Test Plan
all good
```

```
## summary

we only listen to pushes to the deploy branch for git syncs on the editor. this listens to them on on EditorBranches (eg branches v2) branches too!

its behind the `editor-branches-v2-autocommit` flag and NOT the `editor-branches-v2` flag

## test plan

create a new branch v2. push commits to it. make sure they sync!
- i lwk told my claude to do this and tested like that...
```

```
video proof:

https://github.com/user-attachments/assets/227afe40-…

(ignore the middle part taking like 8 years my devboxes r still kindaaa fucked but the first half is on main and the second half is fixed)

# clank
…
```

```
## Summary
regressed in #10220

we dont want to do this in lovable style onboarding but we still want to do it in every other case
## Test Plan
```

Test-plan one-liners he uses: `all good`, `all good its behind a flag`,
`unit tests`, `unit tests & reading the code`, `curl it idk`, `ui only`,
`should be all good hopefully`, `video`, `see video in slack <url>`,
`test with the related mint pr`, `make sure X still works`, `^^ passes for
me`, `read it / run in dev / merge / run in prod`.

## Stack and relation lines are not his

`Stacked on #N.`, `Follow-up to #N.`, `Fixes ENG-NNNN.`, `Supersedes #N.`,
`**Stack 2/3** — base: … → followed by …`, `Pair with mintlify/server#N`
all came from AI-written PRs. Put them under `# clank`. What he writes
himself is looser and stays in his part: `regressed in #N`, `depends on
<url>`, `related: #N`, `see mint PR <url>`, `test with the related mint pr`,
`its readonly until all the backend work is done!`.

## Clank markers he has used (standardize on `### clank`)

`# clank` · `## Summary (clanked)` · `below is clanked` ·
`## BELOW IS ALL CLANKED` · `this is what we r bundling according to clank` ·
`my claude wrote some tests …`.
