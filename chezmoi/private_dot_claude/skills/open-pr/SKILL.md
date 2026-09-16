---
name: open-pr
description: Use when opening a pull request, or when asked to push finished work - covers the order, stacking, the description as a commit message, the detail comment, rust crate versions, and the ticket updates
---

# Open a pull request

## Overview

One ordered procedure, from a finished branch to a registered PR with its
ticket updated. Every step here exists because skipping it cost something
real; the reasons are attached so a future change can weigh them.

This holds in every repository, personal or otherwise — the `ABCD-NNNN` in the
title, the Jira loop at the end, and the shape of the description.

**Core principle: the description is the squash commit message.** Write it as
a commit body and put the long discourse in a comment, in every repository,
so there is one habit rather than one per repository.

For that to be true rather than aspirational, the repository has to squash
with `squash_merge_commit_title: PR_TITLE` and
`squash_merge_commit_message: PR_BODY`, which `gh stack merge` obeys:

```bash
gh api repos/{owner}/{repo} --jq '{squash_merge_commit_title, squash_merge_commit_message}'
```

Some new repos are configured that way, but in some older repos the squash
message is still built from the commits, so until the setting is changed the
shaped description is a convention that history does not pick up. Write it
the same way regardless, and say so once per repository rather than quietly
adapting.

## Stack, or straight onto main

A stack is a chain of branches, each based on the one below it and each with
its own PR, so every diff shows only its own layer. One subtask per layer.

**The test is dependency, not preference: does this branch need code that is
not on `main` yet?** If it does, it has to sit on the branch that carries
that code, and that makes it a layer in a stack. If everything it needs is
already merged, it goes straight on `main`. The base is how the decision is
expressed, not how it is made — so work out the dependency first and the
base follows.

In a phase, each subtask usually builds on the one before, so they stack.
Work that touches something else entirely — a recipe, a checker, CI — is
usually independent and belongs on `main` even in the middle of a phase.

Create the branch with `gh stack add <name>` **when the work starts**, not
when the PR is opened. That is what keeps local tracking right; `git
checkout -b` produces a branch that looks identical and is in no stack.

A stack merges bottom to top, so a layer cannot land before the one below
it, and a merge below rewrites every SHA above — see the replanting section
near the end.

Depth needs no limit. Phase 1 merged a stack of 21 without trouble, so the
number of layers is not a thing to manage.

## The order

1. **Settle roborev on the newest commit.** `roborev fix --list`. roborev
   reviews each commit, so this is not a gate you pass once: it is settled
   repeatedly as the work goes, and what matters here is that nothing is
   running or open on the commit about to be pushed.
2. **Verify every claim the description will make.** Run the suites, read the
   real numbers, re-run anything slow on this branch rather than trusting an
   earlier run. If the change touches a rust crate, settle its version here
   too — see below.
3. **Write the description** as a commit body (see below).
4. **Push and create**, body-first.
5. **Post the detail** as a PR comment.
6. **Register the stack** with `gh stack link`.
7. **Update the ticket and its parent.**

Do not reorder 1 to 3. Opening a PR is the outward-facing step; a description
edited twice in the minutes after it lands reads as work that was not
finished.

## Rust crates: the version bump

If the change touches a rust crate, its version is bumped before the push. A
crate whose code changed and whose version did not is one nothing downstream
can pin, and the omission is invisible in review.

**minor** for a substantial feat — a new capability or a new public surface.
Browser TLS impersonation, a Redis cluster feed, proxy fail-open were each a
minor. **patch** for everything else, including fixes and small feats: a
`fix(rsproxy)`, or build-info-at-startup.

The bump normally rides inside the commit that earns it rather than standing
alone — the fail-open minor went in as part of its own `feat(admin)` commit.
A bump as its own commit is for a branch that was already pushed. Squash-merge
makes the difference invisible; rebase-merge leaves it standing.

When the call is arguable, make it and say so in the PR with the reasoning,
rather than deciding quietly: *leads with a fix, so patch; the case for minor
is that it adds a public config surface and changes connection lifecycle*. A
one-line amend before merge is cheap. A version nobody questioned is not.

## The description

One to three short paragraphs, wrapped at 72 columns, saying what changed and
the non-obvious constraint — usually something a reader could not get from
the diff. Ten to thirteen non-blank lines is the observed range.

No headings, no tables, no bullet lists, no "Based on ABCD-1234, which is
#44" footer. Markdown soft-wraps a paragraph, so wrapping renders identically
on GitHub and fixes `git log`, where nothing wraps it.

Wrap it mechanically rather than by eye:

```python
import textwrap
"\n\n".join(textwrap.fill(" ".join(p.split()), width=72)
            for p in text.strip().split("\n\n"))
```

**Keep:** what changed, and the constraint someone would otherwise "tidy
away" in a year. **Cut:** check results, mutation tallies, what review found,
alternatives rejected, evidence.

## The title

`type(scope): ABCD-NNNN lowercase description`, the same shape as a commit
subject. Squash-merge appends ` (#46)`, so keep the title short enough that
the result still reads.

## The detail comment

Everything cut from the description, posted immediately after creating the
PR, opening with one line saying why it is there:

> Detail, kept out of the description so it does not land in the squash commit.

A reviewer reads it in the same place; `main` never carries it.

## The commands

```bash
gh stack push                       # so gh pr create does not prompt for a remote
gh pr create --base <main, or the branch below> --title "..." --body-file <description>
gh pr comment <n> --body-file <detail>
gh stack link <every pr in the stack, bottom to top>
gh stack view --json                # confirm the branch still carries its PR
```

`--base main` for the bottom of a stack, and the branch below for every other
layer, so each diff shows only its own.

`gh stack link` names **every** PR in the stack, bottom to top, not only the
new one: it sets the whole stack, so a missing number leaves that layer
outside it. In phase 1 that left 8 of 15 PRs stacked and 7 loose, found only
by looking at github.com — `gh stack merge` would have taken the 8 and
stranded the rest on branches that had just been deleted.

**Never `gh stack submit --auto`.** It writes a generated title and no body,
so the PR is empty for as long as it takes a follow-up edit to land, and a
notification fired on creation carries nothing. `--auto` exists to skip the
editor where a body would be typed, so it cannot be made to write one.

## After the merge of anything below

When a PR merges and the stack is rebased, every SHA below moves. A branch
built on the old tip shows as conflicting even though nothing conflicts:

```bash
git fetch origin
git branch -f <each stale branch> origin/<same>
git rebase --onto origin/<base branch> <old base sha> <your branch>
git push --force-with-lease origin <your branch>
```

`--force-with-lease`, never `--force`. GitHub takes a minute to recompute
mergeability, so `CONFLICTING` straight after the push is not a verdict —
check `git merge-base --is-ancestor origin/<base> HEAD` for the real answer.

## A review that lands after the push

Normal, and not a reason to have waited. roborev reviews the commit, so one
can finish after the PR exists.

Wait for it. If it passes there is nothing to do. If it fails, work it
through the same commit-and-review loop as any other finding — fix, commit,
let the next review run, settle it — and only then push the updates to the
PR. Do not push a fix with a review still outstanding on it, for the reason
in step 1.

The description may need nothing at all: it says what changed, and a review
fix usually does not change that. Where it does, edit it, and say in the
detail comment what moved.

## Then the ticket

Append a delivery note to the subtask: what shipped and in which PR,
decisions taken and why, measured results, defects found on the way, and
which acceptance criteria it satisfies. Transition it. Then update the
parent's progress table row and its summary paragraph.

Read a Jira description with `--json` and edit the ADF tree. Never read with
`acli view` and write back plain text: it flattens tables.

## Red flags

| Thought | Reality |
|---------|---------|
| "I will open it and check the numbers after" | That is two description edits and a reviewer watching. |
| "The body explains the whole change, that is good" | It is now a commit message. Explain the change; the story goes in the comment. |
| "gh stack submit is fewer commands" | It opens the PR empty. |
| "It says conflicting, I should rebase again" | Check ancestry first; GitHub lags. |
| "The ticket can wait until the PR merges" | It is the record of decisions, and it is written while they are fresh. |
