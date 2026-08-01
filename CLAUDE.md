# CLAUDE.md

## Git conventions

One topic = one branch, cut fresh from `origin/main`. Before starting
any new topic — a feature, a fix, a shadow experiment — run
`git fetch origin && git switch -c <type>/<topic> origin/main`. Branch
names use the existing `<type>/<kebab-topic>` style — feat, fix, perf,
refactor, docs, ci, ops, chore, shadow, agent.

Never stack a new topic on an existing branch. If the current branch
name does not describe the work about to start, go back to main and cut
a fresh branch first. A shadow or parallel reimplementation of a live
feature gets its own `shadow/<topic>` branch — never more commits on
the branch that built the original.

After a PR merges, delete its branch locally and remotely and return
the checkout to main. Merged branches are never reused. End every
session with the checkout on main, or on a branch whose name matches
the uncommitted work. For long-running experiments prefer a separate
worktree — `git worktree add ../<repo>-<topic> <branch>` — so the
primary checkout stays on main.
