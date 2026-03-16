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
3. Everything else not covered (container_name, working_dir, etc.)
4. Networking (ports, networks, expose)
5. Volumes / mounts
6. Environment / env_file

### Compose Formatting

```yaml
services:
  service-a:
    image: example:latest
    restart: unless-stopped
    container_name: my-service-a
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
    container_name: my-service-b
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
