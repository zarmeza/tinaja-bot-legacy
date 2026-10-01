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
├── Dockerfile                   # Multi-arch Alpine Docker image (ruby:4.0.7-alpine)
├── docker-compose.yml           # Local dev compose setup (bot + headless chromium)
├── Gemfile                      # Bundler dependencies
├── tinaja-bot.gemspec           # Gem specification and runtime requirements
└── Rakefile                     # Rake tasks (:run, :rubocop)
```

### Dynamic Command Loading
Commands in `lib/tinaja-bot/commands/*.rb` are autoloaded dynamically in `TinajaBot::Bot#load_commands`:
1. Scans `lib/tinaja-bot/commands/*.rb`.
2. Infers the command symbol from the filename (e.g. `scrappy.rb` ➔ `:scrappy`).
3. Capitalizes the symbol to find the module under `TinajaBot::Commands` (e.g. `TinajaBot::Commands::Scrappy`).
4. Invokes `.handler`, which must return a `lambda` taking `|event, *args|`.

When creating new commands:
- Create `lib/tinaja-bot/commands/<name>.rb`.
- Structure the module as `TinajaBot::Commands::<Name>`.
- Implement `def self.handler` returning a callable `lambda`.

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
  *Always verify that `bundle exec rake rubocop` passes with 0 offenses before committing.*

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
  - Feature / topic branches: `feat/<name>`, `fix/<name>`, `chore/<name>`, `docs/<name>`.
- **Commit Messages**: Follow Conventional Commits format:
  - `feat: add new discord command`
  - `fix: handle invalid URL in scrappy`
  - `chore: update gem dependencies`
  - `docs: update agent guidelines`
- **Pull Requests**:
  - Open PRs against `main`: `gh pr create --web` or `gh pr create --fill`.
  - Pushes to `main` automatically trigger `.github/workflows/build-and-push.yml`.
