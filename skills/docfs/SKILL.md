---
name: docfs
description: Mount and query public documentation published through llms.txt or llms-full.txt with docfs. Use when researching or searching documentation for an SDK, framework, CLI, library, API, or service site.
---

# docfs

Use `docfs` to expose a documentation site as lazily fetched Markdown files.

## Workflow

1. Run `docfs status`. If it is not mounted, run `docfs mount` and use the mountpoint it reports. The default is `/Volumes/docfs`, with `/tmp/docfs` as the macOS fallback.
2. Read a known page directly as `<mountpoint>/<domain>/<path>.md`.
3. For discovery, list the domain directory first. This resolves the site's `llms.txt` manifest and warms its tree.
4. Search warmed docs with `rg`. If a cold listing returns zero-byte files, wait briefly for background hydration or read a target file directly before searching.
5. Run `docfs sync <domain>` to check for a newer deployment. Run `docfs evict <domain>` to discard cached state and resolve it again.

## Examples

```sh
docfs mount
docfs status
ls /tmp/docfs/docs.example.com
rg "authentication" /tmp/docfs/docs.example.com
cat /tmp/docfs/docs.example.com/api/quickstart.md
```

Only public documentation is available. Do not use this for authenticated or private docs.
