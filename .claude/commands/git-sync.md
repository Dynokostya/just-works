---
description: Sync the root repo and all submodules to their default branch and pull latest
allowed-tools: Bash(git:*)
---

# Git Sync

Switch all repositories (root and submodules) to the default branch and pull latest changes.

## Phase 1: Detect Repositories

Run via Bash:

```bash
git rev-parse --show-toplevel
```

This confirms you're inside a git repository and gives the root path.

Then check for submodules:

```bash
git submodule status 2>/dev/null
```

If the command produces output, submodules are present. Parse each submodule path from the output (second column). If it produces no output or errors, there are no submodules — proceed with the root repo only.

Announce to the user:

```
Repositories found:
  - <root path> (root)
  - <submodule path> (submodule)
  - ...
```

## Phase 2: Detect Default Branch

For each repository (root first, then each submodule), detect the default branch. Run from within that repo's directory:

```bash
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'
```

If that fails (the ref may not exist), fall back to:

```bash
git remote show origin 2>/dev/null | grep 'HEAD branch' | sed 's/.*: //'
```

If both fail, check whether `main` or `master` exists locally:

```bash
git branch --list main master
```

Pick whichever exists. If both exist, prefer `main`. If neither exists, report the error for that repo and skip it.

## Phase 3: Sync

For each repository, run these commands in sequence. Stop processing a repo if any command fails and report the error.

1. **Fetch all remotes:**

```bash
git fetch --all --prune
```

2. **Switch to the default branch:**

```bash
git checkout <default-branch>
```

If checkout fails due to uncommitted changes, report this to the user and skip the repo. Do not stash, reset, or discard changes.

3. **Pull latest:**

```bash
git pull
```

## Phase 4: Report

After processing all repositories, present a summary:

```
Sync complete:
  ✓ <root path> — switched to main, pulled (up to date / X commits pulled)
  ✓ <submodule path> — switched to master, pulled (up to date / X commits pulled)
  ✗ <submodule path> — uncommitted changes, skipped
```

If all repos synced successfully, no further action needed. If any failed, list what the user needs to resolve.

## Rules

- Do not stash, reset, or discard uncommitted changes. If a repo has dirty state, skip it and report.
- Do not modify submodule references in the parent repo. This command syncs each repo independently.
- Process the root repo first, then submodules in the order they appear.
- If no git repository is found in the current directory, tell the user and stop.
