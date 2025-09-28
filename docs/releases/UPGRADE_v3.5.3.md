# Upgrade v3.5.3

## Changes
- Externalized CLAUDE.md to `templates/CLAUDE.md.tpl`, rendered via `envsubst`.
- Shell function installer OFF by default (only runs with `--full`).
- Version bump to 3.5.3.

## Note on Existing CLAUDE.md Files
If you have custom instructions in your existing CLAUDE.md, they are preserved in `CLAUDE.md.original` before the new template is rendered. Check this file if you need to recover any custom prompts or instructions.

## Test
```bash
DRY_RUN=1 ./claude-chroma.sh test-lean "$PWD"
DRY_RUN=1 ./claude-chroma.sh --full test-lean "$PWD"
bash -n claude-chroma.sh
```