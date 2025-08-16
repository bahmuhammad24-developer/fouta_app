# Codex Prompt Spec (Project Standard)

To maintain consistency in how we communicate with the Codex agent for code changes, infrastructure updates, or documentation updates, all prompts MUST follow this format:

---

### Prompt Structure

REPO
repository: <owner>/<repo>
base_branch: <branch>
new_branch: <feature-or-fix-branch>

GOALS
One or more clear outcome statements (what we want, why).

CHANGES
<file path> (EDIT/NEW/DELETE)
Explicit instructions for what to add, change, or remove.

Use code blocks where exact content is required.

ACCEPTANCE
Bullet list of conditions to confirm the change works as intended.

COMMIT & PR
commit_message: "<concise commit message>"
open_pr:
  title: "<PR title>"
  target: <branch>
  body: |
    - Clear bullet list summary of the changes and why they were made.

---

### Notes for Future AIs
- **Be explicit**: include file paths and whether the file is NEW, EDIT, or DELETE.  
- **Atomic branches**: always use `new_branch` so PRs are scoped.  
- **Acceptance criteria**: describe how success is measured (build passes, deploy runs, tests green, etc).  
- **Documentation-first**: if a change involves operational knowledge, also update `docs/ops/` or `docs/history/`.  
- **Commit & PR**: must include both a descriptive commit message and a PR body with context.  
