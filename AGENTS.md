# TinajaBot Agent Guide

Welcome to the **TinajaBot** codebase. This document outlines project architecture, conventions, workflows, and developer commands for AI coding assistants.

---

## 1. Project Overview

- **Purpose**: A Discord bot for the *TINAJA Ingeniería* community.
- **Package Type**: Packaged as a Ruby gem (`tinaja-bot.gemspec`).
- **Core Technology**: Ruby 4.0.7, [`discordrb`](https://github.com/shardlab/discordrb) (~> 3.8).
- **Default Command Prefix**: `!`

---

## 2. Architecture & File Structure

```text
.
├── bin/
│   └── tinaja-bot               # CLI executable (accepts ARGV token and client_id)
├── lib/
│   ├── tinaja_bot.rb            # Main TinajaBot::Bot class and dynamic command loader
│   └── tinaja-bot/
│       ├── version.rb           # Gem version definition
│       └── commands/            # Autoloaded command modules
│           ├── exercism.rb      # !exercism <username> (profile lookup via HTTParty)
│           ├── scrappy.rb       # !scrappy <url> (web screenshots via Watir/Selenium)
│           └── unexpo.rb        # !unexpo (community greeting)
├── k8s/                         # Kubernetes deployment manifests and samples
├── spec/                        # RSpec suite (mirrors lib/ under spec/tinaja_bot/)
│   ├── spec_helper.rb           # Loads TinajaBot + support doubles, RSpec config
│   ├── support/fake_event.rb    # Stand-in for a discordrb message event
│   └── tinaja_bot/
│       ├── bot_spec.rb          # Command loading / registration
│       ├── commands/            # One spec per command module
│       └── fixtures/            # Command modules used only by specs
├── Dockerfile                   # Multi-arch Alpine Docker image (ruby:4.0.7-alpine)
├── docker-compose.yml           # Local dev compose setup (bot + headless chromium)
├── Gemfile                      # Bundler dependencies
├── tinaja-bot.gemspec           # Gem specification and runtime requirements
└── Rakefile                     # Rake tasks (:run, :spec, :rubocop, default)
```

### Dynamic Command Loading
Commands in `lib/tinaja-bot/commands/*.rb` are autoloaded dynamically in `TinajaBot::Bot#load_commands`:
1. Scans `lib/tinaja-bot/commands/*.rb`.
2. Infers the command symbol from the filename (e.g. `scrappy.rb` ➔ `:scrappy`).
3. Derives the module name via `Bot#module_name`, which snake_case ➔ CamelCase (`two_words.rb` ➔ `TwoWords`).
4. Looks that constant up under `TinajaBot::Commands` and calls `.handler`, which must return a `lambda` taking `|event, *args|`.

When creating new commands:
- Create `lib/tinaja-bot/commands/<name>.rb`.
- Structure the module as `TinajaBot::Commands::<Name>`.
- Implement `def self.handler` returning a callable `lambda`.
- **Naming:** the filename must be the snake_case form of the module. `!two_words` ➔ `two_words.rb` ➔ `TinajaBot::Commands::TwoWords`. A mismatch raises `NameError` at boot.
- Add a spec at `spec/tinaja_bot/commands/<name>_spec.rb` (see Testing below).

---

## 3. Tooling & Development Commands

### Dependency Management
- **Ruby Version**: Managed via `.ruby-version` (`4.0.7`).
- **Install dependencies**:
  ```sh
  bundle install
  ```

### Running the Bot
- **Local development (loads `.env` via `dotenv`)**:
  ```sh
  bundle exec rake run
  ```
- **Direct CLI runner**:
  ```sh
  bundle exec bin/tinaja-bot <DISCORD_TOKEN> <CLIENT_ID>
  ```

### Linting & Quality
- **RuboCop**:
  ```sh
  bundle exec rake rubocop
  ```
- **RSpec**:
  ```sh
  bundle exec rake spec
  ```
- **Both** (default task):
  ```sh
  bundle exec rake
  ```
  *Always verify `bundle exec rake` passes before committing: specs green and 0 RuboCop offenses.*

Spec conventions:
- `spec/spec_helper.rb` is auto-required via `.rspec`; don't require it again.
- Spec paths mirror `lib/`: `lib/tinaja-bot/commands/exercism.rb` ➔ `spec/tinaja_bot/commands/exercism_spec.rb`. `RSpec/SpecFilePathFormat` enforces this.
- Handlers are exercised by calling `.handler` with a `FakeEvent` (`spec/support/fake_event.rb`), which records `responses` and `files`. No gateway connection is needed.
- Use `instance_double` for collaborators (`Watir::Browser`, `HTTParty::Response`, `Discordrb::Commands::CommandBot`) — `verify_partial_doubles` is on.
- Anything writing to disk (e.g. `scrappy`'s `screenshot.png`) should run inside a `Dir.mktmpdir` + `Dir.chdir`.

### Docker & Infrastructure
- **Build Docker image**:
  ```sh
  docker build -t tinaja-bot .
  ```
- **Run with Docker Compose**:
  ```sh
  docker compose up
  ```
  Note: `scrappy` relies on `BROWSER_HOSTNAME` and `BROWSER_PORT` pointing to a remote WebDriver service (e.g., `linuxserver/chromium` or `browserless/chrome`).

---

## 4. Git & Contribution Workflow

- **Branching Model**: GitHub Flow (Trunk-Based Development).
  - Main trunk: `main`.
  - Feature / topic branches: `feat/<name>`, `fix/<name>`, `chore/<name>`, `docs/<name>`, `ci/<name>`.
- **Commit Messages**: Follow Conventional Commits format:
  - `feat: add new discord command`
  - `fix: handle invalid URL in scrappy`
  - `chore: update gem dependencies`
  - `docs: update agent guidelines`
- **Pull Requests**:
  - Open PRs against `main`: `gh pr create --web` or `gh pr create --fill`.
- **Continuous Integration**:
  - `.github/workflows/ci.yml` runs `rake spec` and `rake rubocop` on every pull request and on pushes to `main`, pinned to Ruby `4.0.7` to match the `Gemfile`.
  - It uses `bundler-cache: true`, which reads `Gemfile.lock`. That lockfile is tracked on purpose — do not re-add it to `.gitignore`, or CI will resolve dependencies fresh on every run.
  - `.github/workflows/build-and-push.yml` builds and publishes the image to ghcr.io, and also triggers on pushes to `main`.
  - Local `bundle exec rake` is the same check; run it before pushing rather than waiting for CI.

<!-- carrot-handoff:begin -->
## Handoff notes

This repository uses zanoria to carry a task between agent tools.
The note is `.carrot.md`, committed to this repository.

Before starting work here, run `zanoria load`. If a note exists it
describes work already in progress: read it, follow its `Next action`, and
do not re-derive what its `Decisions` section already settled.

Before you finish, run `zanoria save "<one-line task>"` and then
fill in `Tried and failed` and `Decisions` by hand. The tool can record the
git state; it cannot know what you tried.

Two things to leave alone. `State` is machine-derived and regenerates on
every save, so edits to it are lost. And do not add a `##` heading of your
own: only the six canonical headings round-trip in place, so dated or
thematic context belongs under a `###` inside an existing section.

Commit the note. An uncommitted note does not survive a context reset.
<!-- carrot-handoff:end -->
