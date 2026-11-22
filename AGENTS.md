# AGENTS.md

Operating manual for AI coding agents (pi, Claude Code, ...) working in this repository. Read this before touching anything. It states what the project is, which commands matter, and the constraints that silently break the build, the push, or shared Roblox state when ignored. The README is the human-facing landing page; this file is the superset.

## What this project is

**Advanced Roblox Setup** is a Roblox game template built on one premise: the game is a software project.

- **The language is TypeScript.** `src/` compiles to Luau with roblox-ts into `out/`, and Rojo syncs it into Studio and builds the `.rbxl` places. Server code (`src/server`) runs on the Roblox server, client code (`src/client`) on the client, shared code (`src/shared`) on both.
- **Git is the source of truth.** Studio consumes git; it does not author it. Studio-built content is pulled into `place/` (`npm run place:fetch`) and shipped back by Rojo. Edits made directly in Studio never reach git and can be overwritten.
- **Quality gates are non-negotiable.** Formatting, lint (TypeScript and Luau), types, docs, dependencies, and secrets are checked by git hooks locally and by CI. `npm run check` runs all of them.
- **Tests run in the engine.** Jest Lua specs execute inside a real Roblox server through Open Cloud Luau execution (`npm test`).
- **Roblox engine knowledge comes from a local reference.** The creator docs are cloned into `roblox-creator-docs/` as part of the setup; search it before relying on Roblox API behavior — never guess (see "Roblox documentation reference").
- **The game is documented in `docs/`.** The big picture, design, and progress of the game being built in this repo live in `docs/` — read it to orient before answering questions about the game (see "Game documentation").
- **It is a template.** It is expected to be cloned and started from. It ships with `Workspace`, `Lighting`, and `TextChatService` captured as whole services (no other service content) and without assets; do not "complete" the game.

### Invariants — do not break

1. `npm run check` passes before you commit.
2. No `any` anywhere: type coverage must stay at 100%.
3. Every exported `src/shared` symbol carries a complete JSDoc comment (description, `@param`, `@returns`) — TypeDoc fails the build on missing or incomplete docs.
4. Never hand-edit or commit generated output: `out/`, `include/`, `build/`, `generated-docs/`, `src/shared/assets/`.
5. Studio content changes only through `place/` and `npm run place:fetch`.
6. Commit messages follow Conventional Commits (`feat:`, `fix:`, `chore:`, ...).
7. `.env` values never enter the conversation, output, docs, or the repository; reference `.env.example` instead.

## Commands

| Command                     | What it does                                                                                          |
| --------------------------- | ----------------------------------------------------------------------------------------------------- |
| `mise install`              | Node and every CLI tool, pinned with checksums (`mise.toml` / `mise.lock`)                            |
| `npm install`               | npm packages and the git hooks (Lefthook)                                                             |
| `npm run setup`             | Lune editor type definitions (`~/.lune`)                                                              |
| `npm run watch`             | Recompile TypeScript on save                                                                          |
| `npm run serve`             | Rojo sync into Studio                                                                                 |
| `npm run check`             | **Every local gate** — the CI check job, minus the in-engine tests                                    |
| `npm run build`             | Compile and build `build/game.rbxl` (the game)                                                        |
| `npm run build:test-place`  | Compile and build `build/test.rbxl` (the test place)                                                  |
| `npm test`                  | **Shared state!** Build the test place, upload it as a new saved version, run Jest in a Roblox server |
| `npm run format` / `lint`   | Prettier + StyLua / type-aware ESLint (add `:fix` to repair)                                          |
| `npm run lint:luau`         | selene + luau-lsp over `lune/` and `tasks/`                                                           |
| `npm run lint:md` / `spell` | markdownlint / CSpell                                                                                 |
| `npm run typecheck`         | `tsc --noEmit`                                                                                        |
| `npm run knip`              | Unused files, exports, and dependencies                                                               |
| `npm run docs`              | TypeDoc API docs into `generated-docs/` (generated)                                                   |
| `npm run place:fetch`       | Pull Studio-authored content into `place/` (see "Studio content pipeline")                            |
| `npm run roblox:docs`       | Fetch or refresh the local Roblox creator docs clone into `roblox-creator-docs/`                      |
| `npm run assets:sync`       | Upload `assets/` and regenerate the typed asset module                                                |

Fresh machine order: `mise install` → `npm install` → `npm run setup` → `cp .env.example .env` → `npm run roblox:docs`.

## Quality gates

`npm run check` runs, in order: format, lint, lint:luau, lint:md, lint:ci (actionlint), spell, typecheck, coverage:types, knip, docs, assets:check, build. The strict ones:

- **TypeScript:** `strict` plus `noUncheckedIndexedAccess`, `noImplicitOverride`, `noImplicitReturns`, `noFallthroughCasesInSwitch`, `allowUnreachableCode: false`. ESLint adds `strictTypeChecked` + `stylisticTypeChecked` + the roblox-ts rules; `consistent-type-imports` and `explicit-module-boundary-types` are errors; `while (true)` game loops are allowed.
- **Docs:** TypeDoc validates `notExported`, `invalidLink`, `notDocumented` with `treatWarningsAsErrors` — a missing or incomplete JSDoc on a `src/shared` export is a **build error**. Test files and the `*.client.ts` / `*.server.ts` entry points do not need doc comments.
- **Luau:** selene (`std = "roblox"`) and luau-lsp strict mode over `lune/` and `tasks/`, via `lune run analyze` (downloads Roblox type definitions once per luau-lsp version into `.cache/`).
- **Knip:** entries are `*.client.ts`, `*.server.ts`, `jest.config.ts`, and spec files — anything unreachable from them is a failure. `@rbxts/types` and `@rbxts/compiler-types` are expected peers, not dead weight.
- **Assets:** `asphalt sync cloud --dry-run` fails when a file in `assets/` is not in the cloud lockfile.

**Git hooks** (Lefthook, installed by `npm install`): pre-commit runs Prettier, ESLint, and StyLua (fixes are restaged), plus gitleaks and CSpell on staged files; commit-msg runs commitlint (Conventional Commits); pre-push runs typecheck + lint. Do not fight them — run `npm run format` and `npm run lint:fix`, and let the hook restage.

## File layout

- `src/client/` → `StarterPlayerScripts.TS` (client scripts)
- `src/server/` → `ServerScriptService.TS` (server scripts)
- `src/shared/` → `ReplicatedStorage.TS` (module scripts, both sides)
- `src/**/__tests__/*.spec.ts` — Jest specs; **present in the test place only**
- `src/shared/assets/` — generated by Asphalt; import from here, never edit
- `place/` — Studio-authored content: `replicated-models/` and `server-models/` (one `.rbxm` per child of the place's `Models` folders), and `Workspace.rbxm`, `Lighting.rbxm`, `TextChatService.rbxm` (whole services)
- `assets/` — source assets; `asphalt.lock.toml` — the lockfile
- `lune/` — Luau tooling scripts (place fetch, test runner, analysis)
- `tasks/` — Luau that runs inside Roblox (the Jest bootstrap)
- `docs/` — documentation of the game itself (see "Game documentation")
- `default.project.json` — the game; `test.project.json` — the test place (game + specs + harness)
- `out/`, `include/`, `build/`, `generated-docs/`, `.cache/` — **generated; never edit or commit**
- `roblox-creator-docs/` — local clone of the Roblox creator docs (part of the setup, `npm run roblox:docs`); gitignored, not part of the project (see below)

## Game documentation

`docs/` is where the game being built in this repo is documented: the big picture, design decisions, and current progress. It has **no required structure** — the game decides what files it needs, and [docs/README.md](docs/README.md) explains the folder.

- It is hand-written, committed project content — distinct from `generated-docs/` (generated API docs) and `roblox-creator-docs/` (the engine reference clone), both gitignored.
- Read it to orient when a question is about the game, not the toolchain.
- Keep it true: edit in place when the game changes, delete what is no longer true, and prefer links to code or the engine reference over copies.

## Studio content pipeline

`npm run place:fetch` pulls Studio-authored content out of a saved place into `place/`, where Rojo ships it. By default it captures the **children of the onboarded folders**: `ReplicatedStorage.Models` → `place/replicated-models/` and `ServerStorage.Models` → `place/server-models/`, one `.rbxm` per child (stale `.rbxm` files in those directories are deleted on each fetch), and the **entire `Workspace`, `Lighting`, and `TextChatService` services** → `place/<Service>.rbxm`.

Whole-service capture is **opt-in**: the template onboards `Workspace`, `Lighting`, and `TextChatService` by default. Do not onboard other services (e.g. `StarterGui`, `Teams`) unless the task calls for it.

### Onboarding a service

To capture a whole service (e.g. `ReplicatedFirst`), update both of these **in sync** — they form one pipeline, and a mismatch either ships stale content into Studio or silently drops Studio edits:

1. Add the service name to `SERVICES` in `lune/fetch-place.luau` (currently `{ "Workspace", "Lighting", "TextChatService" }`).
2. Add a matching node to the top level of `tree` in `default.project.json`:

   ```json
   "ReplicatedFirst": { "$path": "place/ReplicatedFirst.rbxm" }
   ```

3. Make sure the saved place's service contains the desired content, run `npm run place:fetch`, and commit the new `place/ReplicatedFirst.rbxm`.
4. Verify: `npm run build` must succeed, and a Rojo sync in Studio must show the content.

Rules:

- Keep the two files in sync; no quality gate checks this.
- Never onboard a service Rojo already owns (`ServerScriptService`, `StarterPlayerScripts`, `ReplicatedStorage.TS`, ...) — those nodes hold the compiled TypeScript.
- The entire `Workspace` service is Rojo-owned: all Studio-authored Workspace content is captured into `place/Workspace.rbxm`.
- `test.project.json` does not mount `place/`; onboarding a service affects the game place only.

## Assets

Put files in `assets/`, set `ASPHALT_API_KEY` (needs `asset:read` and `asset:write`), and run `npm run assets:sync`. Asphalt uploads the files to the creator in `asphalt.toml`, updates `asphalt.lock.toml`, and generates the typed asset module in `src/shared/assets/`. Commit the new files, the lockfile, and the generated module together — CI's `assets:check` fails on drift.

## Tests

- Specs live in `src/**/__tests__/*.spec.ts` and import `describe` / `expect` / `it` from `@rbxts/jest-globals`.
- They run inside a real Roblox server, not a simulator: `npm test` builds `test.project.json` → `build/test.rbxl`, uploads it as a new **saved** version of the shared test place, then runs `tasks/run-tests.luau` through Open Cloud Luau execution.
- Requires `ROBLOX_API_KEY` (permissions `universe.places:write` and `universe.place.luau-execution-session:write`), `ROBLOX_TEST_UNIVERSE_ID`, and `ROBLOX_TEST_PLACE_ID`. Use a separate, private experience for tests.
- **`npm test` mutates shared state and consumes Roblox rate limits — do not run it casually.** Run it only when a test change actually needs in-engine verification.
- There is no test-coverage report for code running in Roblox.

## CI/CD

`ci.yaml` (pull requests, pushes to `main`, manual):

1. **check** — every gate in `npm run check`; uploads `build/game.rbxl` as an artifact.
2. **secrets** — gitleaks over the full history.
3. **dependency-review** — pull requests only; fails on newly vulnerable dependencies (high and above).
4. **test** — `npm test` in Roblox. Skipped unless `vars.ROBLOX_TEST_PLACE_ID` is set, and always skipped on fork PRs (they have no secret access). Serialized by a concurrency group because the test place is shared.
5. **deploy** — pushes to `main` only, after check + secrets + (test or skipped) pass; publishes the exact `game.rbxl` from step 1 with rbxcloud, behind the `production` environment.

Repository settings (local analogs in `.env.example`):

| Kind                         | Name                                                                                       |
| ---------------------------- | ------------------------------------------------------------------------------------------ |
| Variables (repository-level) | `ROBLOX_TEST_UNIVERSE_ID`, `ROBLOX_TEST_PLACE_ID`, `ROBLOX_UNIVERSE_ID`, `ROBLOX_PLACE_ID` |
| Secrets                      | `ROBLOX_TEST_API_KEY`                                                                      |
| Secrets (env: `production`)  | `ROBLOX_DEPLOY_API_KEY` (place publishing permission)                                      |

All four IDs must be **repository-level** variables: GitHub does not expose environment-level variables in job-level `if:` conditions, and the deploy gate reads `vars.ROBLOX_PLACE_ID` there. Put `ROBLOX_DEPLOY_API_KEY` on a `production` environment to add required reviewers before publishing.

`docs.yaml` publishes the TypeDoc API docs to GitHub Pages when the `DEPLOY_DOCS` variable is `true` (and Pages source is set to GitHub Actions).

## Toolchain and updates

| Tool                                                                                                    | Role                                                     |
| ------------------------------------------------------------------------------------------------------- | -------------------------------------------------------- |
| [mise](https://mise.jdx.dev)                                                                            | Pins Node and the CLI tools, with checksums              |
| [roblox-ts](https://roblox-ts.com)                                                                      | Compiles TypeScript to Luau                              |
| [Rojo](https://rojo.space)                                                                              | Builds places and syncs files into Studio                |
| [Lune](https://lune-org.github.io/docs)                                                                 | Runs the Luau tooling scripts in `lune/`                 |
| [Asphalt](https://github.com/jackTabsCode/asphalt)                                                      | Uploads assets and generates typed asset IDs             |
| [rbxcloud](https://github.com/Sleitnick/rbxcloud)                                                       | Publishes the place from CI                              |
| [Jest Lua](https://jsdotlua.github.io/jest-lua/) via `@rbxts/jest`                                      | Test runner, executed inside a Roblox server             |
| [ESLint](https://eslint.org) + [typescript-eslint](https://typescript-eslint.io)                        | Type-aware linting, plus roblox-ts and JSDoc rules       |
| [Prettier](https://prettier.io) / [StyLua](https://github.com/JohnnyMorganz/StyLua)                     | Formatting for TypeScript/JSON/Markdown/YAML and Luau    |
| [selene](https://kampfkarren.github.io/selene/) / [luau-lsp](https://github.com/JohnnyMorganz/luau-lsp) | Luau linting and strict type checking                    |
| [Knip](https://knip.dev)                                                                                | Unused files, exports, and dependencies                  |
| [type-coverage](https://github.com/plantain-00/type-coverage)                                           | Fails if any `any` creeps in                             |
| [TypeDoc](https://typedoc.org)                                                                          | API docs for `src/shared`; fails on undocumented exports |
| [CSpell](https://cspell.org) / [markdownlint](https://github.com/DavidAnson/markdownlint-cli2)          | Spelling and Markdown checks                             |
| [actionlint](https://github.com/rhysd/actionlint)                                                       | Checks the GitHub workflows                              |
| [gitleaks](https://github.com/gitleaks/gitleaks)                                                        | Blocks committed secrets                                 |
| [Lefthook](https://lefthook.dev) + [commitlint](https://commitlint.js.org)                              | Git hooks and Conventional Commit messages               |

Updates are by hand: `npm update` for packages, `mise use <tool>@<version>` for the CLI tools, and version tags in `.github/workflows/` (actions use `@vN` tags).

- **The locked trio:** `typescript`, `roblox-ts`, and `@rbxts/compiler-types` move together — roblox-ts bundles an exact TypeScript (currently 5.5.3) and its compiler types only work with that version.
- After a Lune update, run `npm run setup` to refresh the editor type definitions.

## Roblox gotchas

- Roblox API keys auto-expire after 60 days of inactivity. A suddenly expired key is the first thing to check when Roblox APIs start failing.
- `.env` holds all local secrets and is gitignored. Never read its values into docs, commits, or output; reference `.env.example` only.
- `place:fetch` downloads use the login cookie Roblox Studio stores on this machine — you must be logged in to Studio (or use `--file`).

## Roblox documentation reference

`roblox-creator-docs/` is a local clone of [Roblox/creator-docs](https://github.com/Roblox/creator-docs) — the source of create.roblox.com/docs. It holds the complete engine API reference (classes, enums, data types, libraries, globals) alongside the guides and tutorials. It is part of the working setup (`npm run roblox:docs`), gitignored and excluded from every linter, and **not part of the project**: game code must never reference it.

**Rule: never guess Roblox engine behavior.** Before writing or reviewing code that relies on a class, property, method, event, service, or physics behavior, search the local clone. The web is only a fallback when the local search turns up nothing.

- Engine API reference (classes, enums, data types — YAML files): `rg -in "<name>" roblox-creator-docs/content/en-us/reference/engine/`
- Guides and tutorials (markdown): `rg -in "<topic>" roblox-creator-docs/content/en-us/`
- Set up or refresh with `npm run roblox:docs` (clones if absent, refreshes if present).
- Treat it as read-only reference material: never edit, reformat, or commit it.

## Roblox Studio MCP (requires Studio running)

Roblox Studio ships a built-in MCP server (Assistant → Manage MCP Servers → "Enable Studio as MCP server"). When connected, it gives an agent direct tools: script read/edit, Luau execution in the Edit/Client/Server datamodels, game tree exploration, asset search/insert, AI generation (mesh, model, avatar, animation, scene, texture), play mode control, simulated keyboard/mouse input, character navigation, console output, screenshots, and video capture.

- The MCP is only available while Roblox Studio is running with the server enabled (Windows/WSL). If `list_roblox_studios` shows nothing — Studio closed, CI, another machine — the MCP tools do not exist, and the git pipeline (`npm test`, `npm run place:fetch`, Rojo sync) is the only route.
- Call `list_roblox_studios` first and use the returned `studio_id` in every tool call.
- **This is not the source of truth for this repository.** Game code is TypeScript in `src/` (synced by Rojo), and Studio content is under `place/`. Treat the MCP as a tool for inspection, playtesting, and prototyping: changes made directly in Studio never reach git and can be overwritten by the next Rojo sync or `place:fetch`.
- `save_place` creates a new version of a **shared cloud place** — same caution as `npm test`; do not call it casually.
- Play mode is Studio's standard "Play" (a single local player; Client and Server datamodels are accessible). There are no server-only or multi-client modes.
- `screen_capture` returns the image as **inline data without a file path** (unlike `video_capture`, which returns artifact paths). If a workflow must hand the image to a separate process that only accepts file paths, note that Studio also persists captures to `%LOCALAPPDATA%\Roblox\tmp-capture-storage\` as extensionless files (e.g. `wob-2548000006`) — copy the newest one to a `.png` path.
- `Render` is unavailable in the `execute_luau` context (e.g. `Render:CaptureScreenshot` fails); use `screen_capture` instead.

## Definition of done

- `npm run check` passes (pre-push re-runs typecheck + lint).
- Claims about Roblox engine behavior are verified against `roblox-creator-docs/` (web only when the local clone has no answer).
- `npm test` passes **only if** the change actually needs in-engine verification — remember it mutates shared state.
- `docs/` reflects the change when it affects the game's big picture or current state — keep it true, edit in place.
- The commit message is Conventional, and the hooks are satisfied.
- Generated output is consistent with source: `assets/` matches `asphalt.lock.toml` and `src/shared/assets/`; Studio content changes live in `place/`.
