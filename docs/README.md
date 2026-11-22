# Game documentation

This folder is the home for documentation about **the game** built in this repository — what it is, how it works, and where it stands. The root [AGENTS.md](../AGENTS.md) is the operating manual for _working in this repo_; this folder documents _the game itself_.

There is no required structure. Create whatever the game needs — a design overview, notes per system, a progress log — and grow the folder as the game does.

## What belongs here

- **The big picture** — what the game is, the core loop, its rules and pillars.
- **Design decisions** — how systems, mechanics, and content work, and why.
- **Progress and activity** — the current state of the game and what changed recently. Git history is the full log; this folder is the curated view.

## What does not belong here

- How to build, test, or run the project — that is [AGENTS.md](../AGENTS.md).
- Generated or reference material — `generated-docs/` (API docs) and `roblox-creator-docs/` (engine reference) are gitignored and not part of the project.
- Secrets and credentials — ever. The environment holds them; `.env.example` lists what exists.

## Rules

- **Keep it true.** Docs that drift from the game are worse than no docs: edit in place when the game changes, and delete what is no longer true.
- **Write less, sync often.** A few current pages beat a pile of stale ones.
- **Point, don't copy.** Link to the code, configs, and the engine reference instead of duplicating their contents.
