# Project Management Ruby API

## Tech stack

<table>
  <tr>
    <td align="left">
      <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/ruby/ruby-original.svg" alt="Ruby" width="48" height="48" /><br />
      <strong>Ruby</strong><br />
      3.4.12
    </td>
    <td align="left">
      <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/rails/rails-plain-wordmark.svg" alt="Rails" width="48" height="48" /><br />
      <strong>Rails</strong><br />
      8.1
    </td>
    <td align="left">
      <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/postgresql/postgresql-original.svg" alt="PostgreSQL" width="48" height="48" /><br />
      <strong>PostgreSQL</strong><br />
      18
    </td>
  </tr>
</table>

| Layer | Technology |
|-------|------------|
| App server | Puma 8 |
| Auth | bcrypt + session tokens + refresh tokens |
| Serialization | jsonapi-serializer |
| Pagination | Cursor (keyset), no gem |
| Business logic | ActiveModel form objects |
| File uploads | Active Storage (project cover images) |
| I18n | rails-i18n, i18n-tasks (`pt-BR` default, `en`) |
| Security | rack-attack, rack-cors |
| Testing | RSpec, Factory Bot, Faker, SimpleCov |
| Linting & security | RuboCop (Omakase), Brakeman, bundler-audit |
| Env loading | dotenv-rails (development and test) |
| Containers | Docker, Docker Compose |
| Local email | Mailpit |
| CI | GitHub Actions |
| API docs | OpenAPI 3.1 + Redoc |

## Requirements

- [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/)

All commands (Rails, Bundler, RSpec, RuboCop) run inside the `api` container. Running the app directly on the host is not supported: the development config sends mail to the `mailpit` host and connects to the `db` host, which only resolve inside Compose.

Technical choices and their rationale are documented in [TECHNICAL_DECISIONS.md](TECHNICAL_DECISIONS.md) (Portuguese).

## Setup instructions

```bash
git clone <repository-url>
cd project_management_ruby_api

cp docker-compose.sample.yml docker-compose.yml
cp .env.example .env

docker compose up --build
```

On first boot, the API container runs `db:prepare` automatically via `bin/docker-entrypoint`.

Compose starts these services: `api`, `db`, and `mailpit`.

## Environment variables

Copy `.env.example` to `.env` and adjust values as needed. The "Example" column shows the value in `.env.example`; the "Fallback in code" column shows what applies when the variable is unset.

| Variable | Description | Example | Fallback in code |
|----------|-------------|---------|------------------|
| `POSTGRES_HOST` | PostgreSQL host | `db` | credentials, then `db` |
| `POSTGRES_PORT` | PostgreSQL port | `5432` | credentials, then `5432` |
| `POSTGRES_USER` | Database user | `postgres` | credentials, then `postgres` |
| `POSTGRES_PASSWORD` | Database password | `postgres` | credentials, then `postgres` |
| `POSTGRES_DB` | Database name prefix (`_development` / `_test` are appended outside production) | `project_management_ruby_api` | credentials, then `project_management_ruby_api` |
| `SECRET_KEY_BASE` | Rails secret key base | dev placeholder | *required in production* |
| `PORT` | Puma port inside the container | `3000` | `3000` |
| `RAILS_MAX_THREADS` | Puma thread count / DB pool size | `3` | `3` (pool: credentials, then `5`) |
| `RAILS_LOG_LEVEL` | Log level in production | `info` | `info` |
| `FRONTEND_URL` | Frontend origin used in links inside auth emails | `http://localhost:5173` | *required* (mailers fail without it) |
| `CORS_ORIGINS` | Allowed browser origins, comma-separated | `http://localhost:5173` | none (merged with `cors.origins` from credentials) |
| `APP_HOST` | Public API host for mailer URLs in production | `localhost:3000` | *required in production* |

Never commit `.env` or real secrets. Keep `.env.example` updated when adding new variables.

## Running locally

### With Docker (recommended)

```bash
docker compose up
```

| Resource | URL |
|----------|-----|
| API | [http://localhost:3000](http://localhost:3000) |
| API docs (Redoc) | [http://localhost:3000/docs](http://localhost:3000/docs) |
| Mailpit UI | [http://localhost:8025](http://localhost:8025) |

Health check:

```bash
curl http://localhost:3000/up
```

Run Rails commands inside the container:

```bash
docker compose exec api bin/rails console
docker compose exec api bin/rails db:migrate
```

Development mail goes to Mailpit (`mailpit:1025` SMTP inside Compose).

### Seed data

```bash
docker compose exec api bin/rails db:seed
```

Creates a confirmed user you can sign in with right away, owning 100 projects:

| Email | Password |
|-------|----------|
| `user@example.com` | `12345678` |

### Locale

API messages default to `pt-BR`; `en` is also available. The locale comes from the `locale` cookie, then from the `Accept-Language` header, then the default:

```bash
curl -H "Accept-Language: en" http://localhost:3000/api/v1/projects
```

## Running tests

```bash
docker compose exec api bin/rspec
```

Run the full CI suite (setup, RuboCop, i18n-tasks health, bundler-audit, Brakeman, RSpec), the same checks GitHub Actions runs:

```bash
docker compose exec api bin/ci
```

## API documentation

Interactive docs are served by Redoc at:

| Resource | URL |
|----------|-----|
| Docs UI | [http://localhost:3000/docs](http://localhost:3000/docs) |

The page has an English / Português switch and picks the browser language by default.

Source files:

- `public/docs/index.html` — Redoc page (holds `SPEC_VERSION`)
- `public/openapi/spec.yml` — English OpenAPI entry point
- `public/openapi/paths/` — one file per endpoint (`authentication/`, `user/`, `project/`)
- `public/openapi/components/` — shared schemas, responses, and security schemes
- `public/openapi/pt-BR/` — Portuguese mirror of the whole tree

When adding or changing endpoints:

1. Add or update the path file under `public/openapi/paths/` and wire it in `spec.yml`
2. Update `components/` if needed
3. Mirror the change in `public/openapi/pt-BR/` (same files and `$ref`s, translated text)
4. Bump `SPEC_VERSION` in `public/docs/index.html`, otherwise browsers keep serving the cached spec

### Authentication

Protected endpoints require a Bearer session token:

```http
Authorization: Bearer <token>
```

1. Register — `POST /api/v1/user/registrations`
2. Confirm email — `POST /api/v1/user/email/confirmations` (token from the email; inspect it in Mailpit)
3. Sign in — `POST /api/v1/user/authentications` → `token` in the JSON body; `refresh_token` is set as an encrypted httpOnly cookie
4. Call protected endpoints with `Authorization: Bearer <token>`
5. Refresh when expired — `PATCH /api/v1/user/session/refreshes` (reads the `refresh_token` cookie)
6. Revoke sessions — `DELETE /api/v1/user/session/revokes` (Bearer required)

Request bodies are flat JSON (not nested under `user`). The full schemas are in the [API docs](http://localhost:3000/docs). Example with `curl`, keeping the refresh cookie in a cookie jar:

```bash
# 1. Register
curl -X POST http://localhost:3000/api/v1/user/registrations \
  -H "Content-Type: application/json" \
  -d '{"first_name":"John","last_name":"Doe","email":"john.doe@example.com","password":"password123","password_confirmation":"password123"}'

# 2. Confirm email (copy the token from the email in Mailpit)
curl -X POST http://localhost:3000/api/v1/user/email/confirmations \
  -H "Content-Type: application/json" \
  -d '{"token":"<token-from-email>"}'

# 3. Sign in: the session token comes in data.token, the refresh token goes to cookies.txt
curl -X POST http://localhost:3000/api/v1/user/authentications \
  -c cookies.txt \
  -H "Content-Type: application/json" \
  -d '{"email":"john.doe@example.com","password":"password123","remember_me":true}'

# 4. Call a protected endpoint
curl http://localhost:3000/api/v1/projects -H "Authorization: Bearer <token>"

# 5. Refresh: reads and rotates the cookie; send remember_me again to keep the 30-day lifetime
curl -X PATCH http://localhost:3000/api/v1/user/session/refreshes \
  -b cookies.txt -c cookies.txt \
  -H "Content-Type: application/json" \
  -d '{"remember_me":true}'
```

To skip steps 1–2, sign in with the seeded user (`user@example.com` / `12345678`).

| Token | Lifetime |
|-------|----------|
| Session (`token`) | 15 minutes |
| Refresh token (`remember_me: true`) | 30 days (persistent cookie) |
| Refresh token (without `remember_me`) | 1 day; the cookie is a browser-session cookie, cleared when the browser closes |
| Email confirmation | 24 hours |
| Password reset | 15 minutes |

### User endpoints (`/api/v1/user`)

| Method | Path | Auth |
|--------|------|------|
| POST | `/api/v1/user/registrations` | Public |
| POST | `/api/v1/user/authentications` | Public |
| POST | `/api/v1/user/email/confirmations` | Public |
| POST | `/api/v1/user/password/resets` | Public |
| PATCH | `/api/v1/user/password/resets` | Public |
| PATCH | `/api/v1/user/session/refreshes` | Public |
| PATCH | `/api/v1/user/profiles` | Bearer |
| DELETE | `/api/v1/user/accounts` | Bearer |
| PATCH | `/api/v1/user/email/changes` | Bearer |
| PATCH | `/api/v1/user/password/changes` | Bearer |
| DELETE | `/api/v1/user/session/revokes` | Bearer |

### Project endpoints (`/api/v1/projects`)

All project endpoints require a Bearer token and only see the current user's projects.

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/projects` | List projects (cursor-paginated) |
| POST | `/api/v1/projects` | Create a project |
| GET | `/api/v1/projects/:id` | Show a project |
| PATCH | `/api/v1/projects/:id` | Update a project |
| DELETE | `/api/v1/projects/:id` | Delete a project |
| POST | `/api/v1/projects/:project_id/favorite` | Mark as favorite |
| DELETE | `/api/v1/projects/:project_id/favorite` | Unmark as favorite |

Create and update accept `multipart/form-data` so `cover_image` can be uploaded (Active Storage).

List query parameters:

| Param | Values |
|-------|--------|
| `search` | Text filter, at least 3 characters |
| `sort` | `name` (default), `recent_start`, `nearest_deadline` |
| `favorite` | `true` or `false` |
| `after` | Cursor from the previous page's `pagination.next` |

Pages hold 20 projects. The response includes `pagination: { next, count, limit }`; `next` is `null` on the last page.

### Rate limiting

rack-attack throttles per IP:

| Rule | Limit |
|------|-------|
| Any request (except `/up`) | 300 per 5 minutes |
| `POST /api/v1/user/authentications` | 10 per minute |

Throttled requests get `429 Too Many Requests`.

## Troubleshooting

**API cannot connect to the database**

- Ensure the `db` service is healthy: `docker compose ps`
- Confirm `POSTGRES_*` values in `.env` match the `db` service in `docker-compose.yml`

**Port 3000 already in use**

Stop the process using port 3000, or change the host mapping in `docker-compose.yml` (for example `'3001:3000'`). Setting `PORT` alone does not change the published host port.

**Bundle install fails in Docker**

```bash
docker compose down -v
docker compose build --no-cache
docker compose up
```

**Pending migrations**

```bash
docker compose exec api bin/rails db:migrate
```

**Docs page loads but endpoints are missing**

Ensure `public/openapi/spec.yml` (and `public/openapi/pt-BR/spec.yml`) is up to date. Redoc reads the spec from `/openapi/spec.yml?v=<SPEC_VERSION>`; if you changed the spec but still see the old version, bump `SPEC_VERSION` in `public/docs/index.html`.

**Emails not arriving locally**

- Confirm the `mailpit` service is up: `docker compose ps`
- Open [http://localhost:8025](http://localhost:8025)
