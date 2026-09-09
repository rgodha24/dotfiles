# Attaching files with gh

Source: https://docs.github.com/en/github-cli/github-cli/attaching-files-with-github-cli
(verified against the installed gh 2.100.0 `gh pr create --help`).

`--attach` uploads a local image or video to GitHub and writes the resulting
URL into the body. Available on `gh issue create|edit|comment` and
`gh pr create|edit|comment`. Needs push access to the repo.

```sh
gh pr create --title "…" --body-file body.md \
  --attach PATH/TO/FIRST-IMAGE --attach PATH/TO/SECOND-IMAGE
gh pr comment 123 --attach 'PATH/TO/IMAGE#ALT-TEXT'
```

## Rules

- Repeat `--attach` per file; the same file can't be attached twice in one
  command. Up to 50 files per command.
- Images and media only (png, jpg, gif, mp4, mov, webm, …). Not text/PDF.
- Alt text: `'path#alt text'`. Defaults to the filename. Not supported on
  videos.
- If some uploads fail, the PR is still created with the ones that worked;
  re-run `gh pr edit --attach` for the rest.

## Placement (this is why the body uses local paths)

If the body already references the file by its local path, gh rewrites that
reference in place instead of appending a copy at the end. So:

1. Write the body with ordinary local paths, above `### clank`:

   ```markdown
   works now

   video proof:

   ![](./demo.mp4)

   after:

   ![the fixed dialog](./after.png)

   ### clank
   …
   ```

   Every attachment gets a terse caption on the line before it (a few
   lowercase words, no sentence). The `#alt text` suffix is for screen
   readers and search, not the caption.

2. Pass each referenced file with `--attach`. Unreferenced attachments get
   appended to the very end of the body, which would put them *below*
   `### clank`; always reference them explicitly.

Videos render as a player only when the `![](path)` reference is the entire
paragraph (blank lines around it). Inside a sentence it renders as a link.
Alt text for rewritten references comes from the Markdown, not the `#` suffix.

## Getting a video in the first place

Screen recordings Rohan drops in are usually `.mov`/`.mp4` in `~/Desktop`
or `~/Downloads`; browser-tool GIFs land wherever the gif tool wrote them.
Use the file as-is; don't transcode unless it's over GitHub's size limit.
