# Project Guidelines

## Architecture & Design Philosophy

- **Extensibility first**: Before implementing any feature, consider what related features could be added in the future. Design abstractions, interfaces, and data models to accommodate foreseeable extensions — without implementing them yet.
- **Maintainability**: Prioritize clean code structure, clear separation of concerns, and consistent patterns. The codebase must be easy to navigate and modify for both humans and AI agents.
- **Configuration via environment**: All runtime configuration is done exclusively through environment variables. No config files, no hardcoded values, no CLI flags for configuration.

## Project Structure

- Keep a flat and intuitive directory layout.
- Document the project structure, tech stack, design decisions, and internal architecture **only** in the `CLAUDE.md` — never in the README.

## Documentation

### README.md

Structure (keep it tight and concise):

1. **Short intro** — one paragraph max
2. **Features** — bullet list
3. **Getting Started**
   - **Configuration** — refer to `.env.example`, do not duplicate variable docs
   - **Development Setup** — reference `docker-compose.dev.yml`
   - **Production Setup** — reference `docker-compose.prod.yml`
4. Any additional info relevant **for users of the repo** (not developers)

The README is user-facing only. No technical deep-dives, no project structure, no architecture docs.

### CLAUDE.md

Keep it updated with every structural change, new component, design decision, or convention. This is the single source of truth for how the project works internally.

### .env.example

- Contains **all** environment variables with default values.
- Each variable has a short description as a comment.
- Include instructions for obtaining tokens/secrets (URLs, CLI commands, etc.).
- This is the **only** place where environment variables are documented. Do not explain them in README, CLAUDE.md, or anywhere else.

## Docker & Compose Conventions

### Compose File Organization

- **`docker-compose.dev.yml`** — development setup with hot reload / volume mounts so containers don't need rebuilding on code changes.
- **`docker-compose.prod.yml`** — production setup pulling pre-built images from GHCR. No local builds needed. Updating = pulling the latest image.

### Service Definition Order

Within each service, order settings as follows:

1. Image / build
2. Execution (command, entrypoint, depends_on, restart, healthcheck)
3. Networking (ports, networks, expose)
4. Everything else not covered above
5. Volumes / mounts
6. Environment / env_file

### Compose Formatting

```yaml
services:
  service-a:
    image: example:latest
    restart: unless-stopped
    ports:
      - "8080:8080"
    networks:
      - app
    volumes:
      - ./data:/data
    environment:
      - FOO=bar

  service-b:
    build: ./service-b
    restart: unless-stopped
    ports:
      - "3000:3000"
    networks:
      - app
    env_file:
      - .env

volumes:
  data:

networks:
  app:
```

- Blank line **between** services, but **not** between settings within a service.
- Blank line **between** top-level blocks (`services`, `volumes`, `networks`).

## CI/CD

- Add GitHub Actions workflow for automatic GHCR image builds when applicable.
- Tag images with `latest` and the git SHA or semver tag.

## Code Style

- Write clean, self-documenting code. Use comments only for non-obvious "why", not "what".
- Prefer explicit over implicit. Prefer simple over clever.
- Handle errors explicitly — no silent swallowing.
- Use consistent naming conventions per language ecosystem (e.g., snake_case for Python, camelCase for JS/TS).

## Workflow

- When modifying existing features or adding new ones, always update `README.md` and `CLAUDE.md` to reflect the changes.
- When adding new environment variables, add them to `.env.example` with description and defaults before using them in code.

# Git Guidelines

## Commit Messages

Follow **Conventional Commits v1.0.0** with emojis.

**Format:**
1. Header (required, single line): `<type>[optional scope][!]: <emoji> <description>`
2. Body (optional): blank line after header, wrap at ~72 chars.
3. Footer (optional): blank line after body (or header if no body).

**Rules:**
- `<type>` must be lowercase and one of the allowed types below.
- `<scope>` is optional, lowercase noun (e.g., auth, api, ui, deps).
- `<description>` is required, imperative mood, concise, no trailing period.
- Description must start with a lowercase letter (no Title Case).
- Only capitalize words when naturally required (e.g., OAuth, WebAuthn, FIDO2, HTTP, iOS).
- Breaking change: add `!` before `:` and include footer:
  `BREAKING CHANGE: <what breaks and how to migrate>`
- Footers may include issue refs: `Fixes #123`, `Refs #456`.

**Emoji + type map (use exactly):**

| Type | Emoji | Meaning |
|------|-------|---------|
| feat | ✨ | new feature |
| fix | 🐛 | bug fix |
| docs | 📝 | documentation |
| style | 🎨 | formatting / whitespace only |
| refactor | ♻️ | code restructuring (no feature/fix) |
| perf | ⚡️ | performance improvement |
| test | ✅ | add/update tests |
| build | 🏗️ | build system or dependencies |
| ci | 👷 | CI configuration/scripts |
| chore | 🧹 | maintenance tasks |
| revert | ⏪ | revert previous commit |

**Type selection:** Prefer `feat`/`fix` for user-visible changes. Otherwise use the most accurate type.

**Examples:**
- `feat(auth): ✨ add passkey login support`
- `fix(api): 🐛 handle missing OAuth refresh token`
- `docs: 📝 document WebAuthn redirect flow`
- `style(ui): 🎨 format CSS and remove trailing spaces`
- `refactor(core): ♻️ extract session validation helper`
- `perf(db): ⚡️ speed up credential ID lookup`
- `test(auth): ✅ add FIDO2 regression tests`
- `build(deps): 🏗️ bump Playwright to latest version`
- `ci: 👷 run lint and tests on PRs`
- `chore: 🧹 update release instructions`
- `revert: ⏪ revert "feat(auth): ✨ add passkey login support"`

**AI co-authorship:** When an AI agent authors or co-authors a commit, add a `Co-authored-by` footer with the agent's identity. Example:
```
Co-authored-by: Claude <noreply@anthropic.com>
```

**Breaking change example:**
```
feat(api)!: ✨ rename /v1/login to /v2/login

BREAKING CHANGE: The /v1/login endpoint was removed. Use /v2/login instead.
Fixes #123
Co-authored-by: Claude <noreply@anthropic.com>
```
