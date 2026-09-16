---
name: git-commit
description: Use when asked to commit, make a commit, commit my changes, or write a commit message - covers composing the message from the staged diff and running git commit
# disable-model-invocation: true
---

You are an expert at writing Git commits. Your job is to write a clear commit message
that describes what the changes do at a high level, but not listing code changes. The
developer can read the diffs. USE concrete outcomes without abstract wording.

# Git Commit

## Overview

Compose a commit message from the staged diff and commit it.

**Core principle: the index is the spec.** What the user staged IS the
commit. Staging is a deliberate act that already answered "what goes in
this commit" - re-deciding it is overriding the user, not helping them.

## The Iron Rule

**Commit exactly what is staged. Never stage anything.**

No `git add`. No `git add -A`, `git add .`, `git add -u`, no `git commit -a`,
no adding "just the one related file". If it is not in the index, it is not
in this commit.

**No exceptions:**
- Not when the unstaged change looks related
- Not when the user said "commit my changes" (the index says which)
- Not when leaving it out makes the commit feel incomplete
- Not by splitting the extra work into a second, tidier commit

**Empty index? Stop.** Show `git status --short` and ask what to stage.
Do not pick for them.

## Rationalizations

Every one of these was observed in testing. All are wrong.

| Excuse | Reality |
|--------|---------|
| "They said 'my changes' - that means all of them" | The index is how they said which. Ambiguous words don't outrank an explicit act. |
| "The unstaged file is part of the same feature" | They staged one and not the other. Assume that was on purpose. |
| "A commit without it would be broken/incomplete" | An incomplete commit is theirs to make. A surprise commit is not. |
| "I'll keep it clean by making two commits instead" | Still commits work they held back. Two wrong commits, not one. |
| "`git add -A` is what everyone does" | Not here. It silently destroys staging intent. |
| "The leftover is just noise in `git status`" | Then it stays as noise. Not your call. |

## Workflow

1. `git status --short` and `git diff --staged` - see exactly what is committing.
2. If nothing is staged: stop, show status, ask.
3. `git log -30 --pretty=format:%s` (add `%b` if bodies might exist) - match
   the repo's existing convention: prefix shape, case, tense, length, whether
   bodies or trailers ever appear.
4. Compose the subject. Say what changed and why, at the altitude the history
   uses. Not a list of filenames.
5. Commit with `git commit -m`. Heredoc only if the repo's history actually
   uses bodies.
6. Report `git log -1 --oneline`, and name anything left unstaged or untracked
   so the user knows it is still waiting.
7. If the Git history shows that conventional commits are being used, then
   you MUST use them.
8. If the Git history looks like it contains Jira tickets (e.g. `PRXY-NNNN`),
   then ensure that you use info from the current branch to form the commit title.
   E.g., for a branch like this: `PRXY-<NUMBER>-branch-name` with conventional commits,
   generate a subject like `fix(proxy): PRXY-1234 actual subject text`.

## Message Notes

- **Body only if the history has bodies.** Most repos of config and dotfiles
  are subject-only. A body nobody asked for is noise.
- **No trailers** - no `Co-Authored-By`, no `Generated with` - unless the
  repo's own history already carries them. Check, don't assume.
- Do not include the raw diff output in the commit message.
- Generate the git commit message from ALL STAGED files.
- Use --no-pager git option.
- Make text clear and concise.
- The title MUST NOT be longer than 70 chars

## When the repo uses bodies

- Don't repeat information from the subject line in the message body.
- Describe the actual build and runtime behavior changes.
- Explicitly mention version upgrades, removed artifacts, and test cleanup behavior.
- Cover every major category of staged changes in the summary.
- Avoid abstract phrases such as "make state intentional" or "improve reproducibility" 
  unless immediately explained
- Group fixes per category.
- Use 70 char per line in commit message body.
- Before the grouped change list, write a self-contained technical introduction
  for a developer who is unfamiliar with the affected code. The introduction must:
  - Explain the relevant runtime workflow or previous behavior first.
  - Explain what the change now does differently and the concrete outcome.
  - Connect multiple requests, processes, or components when their relationship
    is necessary to understand the change.
  - Name useful protocol and product concepts, but avoid internal symbols, file
    names, and implementation-level lists.
  - Answer "what problem did this solve?" without requiring the reader to inspect
    the diff.
- Write the introduction as separate paragraphs with one purpose each:
  1. Describe the existing product, protocol, or runtime workflow.
  2. State the newly added capability explicitly and explain how it connects the
     relevant requests, processes, or components to produce the concrete outcome.
  3. Describe each distinct behavioral fix in its own paragraph, including the
     user-visible failure it prevents. Omit this paragraph when there is no
     separate fix.
- Do not combine the workflow, new feature, and separate fix into one dense
  paragraph. For example:

```text
The product sends prompts and responses over separate session APIs rather than
the normal chat stream.

The proxy now supports the new session API and correlates those calls into one
protected conversation, so policy decisions and records remain consistent.

ASK decisions now fail closed immediately when the browser dialog cannot be
shown instead of waiting for confirmation that cannot arrive.
```

- Do not merely restate an implementation mechanism. For example:
  - Weak: "Responses retain prompt context across SSE handoffs."
  - Strong: "The client delivers the answer in a separate resume request after
    the original stream ends with a handoff. The proxy now reconnects that answer
    to the original prompt so policy checks and logging cover the complete
    interaction instead of treating handoff metadata as the final answer."
- Use this structure:
  - Commit title
  - Technical introduction
  - Grouped list of changes
- If change touches AGENTS.md or SKILL.md or any other agentic tool configuration
  then add it to own Agentic Tools section.

## Hooks

If a pre-commit hook fails, report the failure and stop. Never retry with
`--no-verify`. If a hook reformats files, the reformatting is unstaged - do
not sweep it in; tell the user it is there.

## Red Flags - STOP

- About to type `git add` anything
- About to type `commit -a` or `--no-verify`
- Thinking "this other change belongs with it"
- Thinking "I'll just split it into two commits"
- Message names files instead of describing the change

**All of these mean: commit the index as it stands, nothing else.**
