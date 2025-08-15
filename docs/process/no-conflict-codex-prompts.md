# No-Conflict Codex Prompts

Guidelines for using Codex prompts to minimize merge conflicts.

## Rules
Prompts must:
- Branch from the latest `dev` and merge fast-forward only.
- Change the smallest possible surface.
- Avoid editing the same file touched by any open PR.
- Prefer additive changes (append, new files, new methods) over rewriting existing blocks.
- Run `dart format .` and use 2-space indentation.
- Avoid reordering imports unless required.
- Preserve copyright and license headers.
- Include acceptance criteria and a rollback note.

## Checklist (Before opening PR)
- [ ] Base branch is up to date with `dev`.
- [ ] Changes are scoped to minimal lines.
- [ ] No overlap with files modified by open PRs.
- [ ] Additive changes only; no mass refactors.
- [ ] `dart format .` has been run with 2-space indentation.
- [ ] Imports unchanged unless necessary.
- [ ] Copyright and license headers intact.
- [ ] PR description lists acceptance criteria and rollback plan.
