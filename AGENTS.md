# Rails API Engineering Agent

You are a senior Ruby on Rails engineer working on a production-grade Rails API application.

# Mandatory Reading

Before making code changes:

1. Read this file (`AGENTS.md`)
2. Read only files relevant to the requested feature
3. Avoid loading unnecessary context
4. Follow project rules in `.cursor/rules/` when applicable

## Docker (mandatory)

All project commands that depend on the app runtime **must run inside the Docker container**, never on the host.

Compose services: `api` (Rails), `db` (PostgreSQL 18), `mailpit` (local SMTP/UI).

### Always run in the container

- Rails: `rails`, `bin/rails`
- Bundler: `bundle`, `bundle exec`
- Tests: `rspec`, `bin/rspec`, `rake`, `rubocop`, `bin/rubocop`, and similar
- Database: `rails db:*`, `rails dbconsole`
- Generators: `rails generate`
- Console: `rails console`
- CI helpers: `bin/ci`, `bin/brakeman`, `bin/bundler-audit`

### How to run

With Compose services already up (`docker compose up`):

```bash
docker compose exec api <command>
```

Examples:

```bash
docker compose exec api bin/rspec
docker compose exec api bin/rails db:migrate
docker compose exec api bundle install
docker compose exec api bin/rails console
```

Use the service name defined in `docker-compose.yml` (`api`). If `container_name` differs, still prefer `docker compose exec` / `run` with the **service** name, not the container name.

Do **not** use the `Makefile` — it is for human developers only. Always run commands via `docker compose`.

### Allowed on the host

- `docker compose` (up, down, build, ps, logs, exec, run)
- Git and GitHub CLI (`git`, `gh`)
- Editing files in the workspace (editor / agent tools)

### Before running commands

1. Confirm containers are up (`docker compose ps`).
2. Do not install Ruby gems or run migrations directly on the host.
3. For Docker details, use the files in this repo: `Dockerfile`, `Dockerfile.dev`, `docker-compose.yml`, `docker-compose.sample.yml`, and `bin/docker-entrypoint`.

## Primary Goal

Build maintainable, scalable, secure, and testable Rails API code.

Always prioritize:

1. Maintainability
2. Readability
3. Performance
4. Security
5. Simplicity

Avoid overengineering. Do not invent `app/services/`, policy gems, or fat Active Record models when the patterns below already cover the need.

---

## Layer map

Mirror the `User` context for new bounded contexts. Table models live at `app/models/` with flattened class names. Processes, domain constants, and serializers stay under `app/models/<context>/`.

| Layer | Location | Examples |
|-------|----------|----------|
| Persistence | `app/models/*.rb` | `User`, `UserSession`, `UserEmailConfirmation`, `UserPasswordReset` |
| Use cases (processes) | `app/models/<context>/` | `User::Registration`, `User::Email::Confirmation` |
| Domain constants | `app/models/<context>/` | `User::Email`, `User::Password`, `User::Token` |
| Serializers | `app/models/<context>/serializer.rb` | `User::Serializer` |
| Mailers | `app/mailers/` | `UserMailer` |
| HTTP | `app/controllers/api/v1/<context>/` | thin controllers only |

Do **not** reintroduce `app/models/core/`, `ApplicationSolidProcess`, `*::Record`, mappers, entities, repository interfaces, adapters, `Solid::Context` facades, or `app/services/`.

---

## Engineering Rules

---

### Controllers

Controllers must remain thin.

Allowed:

- params / strong params
- authentication (`authenticate_user!` / `skip_before_action`)
- request orchestration (call process, pattern-match result)
- response rendering (via `API::V1::BaseController` helpers)
- session cookie helpers (`set_refresh_token_as_cookie`)

Forbidden:

- business logic
- SQL
- complex conditionals
- inventing an authorization/policy layer unless explicitly requested (this app uses authentication only today)

Call processes with a leading `::` (e.g. `::User::Registration.call(...)`) so `User` never collides with the `API::V1::User` controller namespace if the file uses nested `module`/`class` definitions. Pattern-match on `Solid::Success` / `Solid::Failure(input:)` / `else`.

Protected actions pass the authenticated record as `user: current_user`. Public session-creating actions merge `request_metadata` (`ip_address`, `user_agent`). Refresh reads `cookies.encrypted[:refresh_token]`.

Reference: `API::V1::User::RegistrationsController`, `API::V1::User::ProfilesController`.

---

### Authentication

- Protected endpoints inherit `before_action :authenticate_user!` from `API::V1::BaseController`.
- Public endpoints use `skip_before_action :authenticate_user!`.
- `current_user` is `User.find_signed(bearer_token, purpose: :session_token)` and must be `active?`.
- Clients send the session token as `Authorization: Bearer <token>`.
- Refresh token is an encrypted HTTP-only cookie (`cookies.encrypted[:refresh_token]`), set via `set_refresh_token_as_cookie` when the process returns one.
- Pass `request_metadata` (`ip_address`, `user_agent`) into processes that create sessions (`User::Authentication`).

---

### Business logic (solid-process)

Complex business logic belongs in `Solid::Process` subclasses under `app/models/<context>/`.

Pattern:

- Process: `User::Registration < Solid::Process`
- Controller: `::User::Registration.call(params)`
- Name processes after the use case (`Registration`, `Authentication`, `Change`, `Confirmation`, `Reset`, `Update`, `Refresh`, `Revoke`, `Deletion`, `SendInstructions`). Table models stay flattened (`UserEmailConfirmation`, `UserPasswordReset`) so they do not collide with processes (`User::Email::Confirmation`, `User::Password::Reset`)

Processes must:

- have a single responsibility
- declare `input`; declare `deps` only when injecting (`mailer`, default `UserMailer`)
- be deterministic and testable
- talk to Active Record directly (`User.create`, `user.sessions.create!`, `user.update`)
- orchestrate with `Given`, `.and_then`, `Continue()`, `Failure()`, `rollback_on_failure`
- use `.and_expose(:event_name, %i[keys])` when the controller needs named success values
- keep `deliver_later` **outside** `rollback_on_failure` so mail is not sent if the transaction rolls back
- on business/validation failure: `input.errors.add(...)` then `Failure(:type, input:)`. Use `:invalid_input` when merging AR errors (`input.errors.merge!(user.errors)`); use a specific type for domain rules (`:invalid_token`, `:user_is_not_active`, `:email_not_found`, …)
- on persistence that can fail validation (`User.create`, `user.update`): check success, merge errors, `Failure(:invalid_input, input:)`
- on persistence that must not fail (child records, tokens): bang methods (`create!` / `update!`); `rescue_from StandardError` handles infrastructure errors
- validate a persisted user with `instance_of: User, is: :persisted?` (solid-process validators)
- add Input error translations under `activemodel.errors.models.<process/path>/input` in `config/locales/<context>/`

Canonical reference: `User::Registration`. Other shapes: `User::Authentication` (session + `.and_expose`), `User::Email::Change` (`deps` + mail outside rollback), `User::Profile::Update` (authenticated `user:`).

---

### Models

Avoid fat Active Record models.

Prefer:

- Active Record classes at `app/models/` with flattened names matching the table (`User`, `UserSession`, `UserEmailConfirmation`, `UserPasswordReset`)
- `has_many` associations on the parent with `class_name:` when the association name does not match the class (`has_many :sessions, class_name: "UserSession"`)
- thin Records: associations (`dependent:`), `has_secure_password`, `generates_token_for`, `has_paper_trail`, scopes, and small persistence helpers (`UserSession.revoke_all`)
- modules for domain constants (`User::Email`, `User::Password`, `User::Token`)
- solid-process for use cases, under `app/models/<context>/`

Keep validations and normalization that belong to the use case on the process `input`, not on the Record, unless they are pure persistence constraints.

Avoid callbacks unless necessary. Never bury side effects (mail, tokens, orchestration) in Records — put them in processes.

---

### Frozen String Literal

NEVER add `# frozen_string_literal: true` to the top of the file. REMOVE it if it exists.

---

### API Design

Always:

- version APIs (`/api/v1`)
- when exposing collections, paginate with Pagy (gem is available; no in-app usage pattern yet — follow Pagy docs and keep the response envelope)
- use serializers (`jsonapi-serializer`, e.g. `User::Serializer`) wrapping Active Record from the process result (`data: { user: User::Serializer.new(user) }`)
- use I18n for controller messages under `config/locales/<context>/` (`user.registration.success`), process Input errors under `activemodel.errors.models`, and mailer subjects under `config/locales/<context>/mailer.*.yml`
- keep OpenAPI docs in sync: add/update path files under `public/openapi/paths/`, wire them in `public/openapi/spec.yml`, update `components/` when needed (Redoc UI at `/docs`)
- return proper HTTP status codes
- keep response consistency (`render_json_with_success` / `render_json_with_error` / `render_json_with_model_errors`)
- use Zeitwerk conventions

---

### Tests

Prefer the existing style:

- **Request specs** as the primary coverage for endpoints: `spec/requests/api/v1/<context>/...`
- **FactoryBot** factories under `spec/factories/<context>/`, with `class:` matching the flattened Active Record class (`:user`, `:user_session`, `:user_email_confirmation`, `:user_password_reset`)
- Thin **model specs** only when persistence behavior needs unit coverage (`spec/models/user_spec.rb`, `spec/models/user_session_spec.rb`)
- Reuse helpers in `spec/support/` (`AuthHelpers`) and shared examples (`an unauthorized API request`)
- Keep process Input error keys covered (`spec/models/user/error_messages_spec.rb`) when adding `errors.add`

Do not invent process/unit specs as the primary coverage. Mirror an existing request spec when adding an endpoint.

---

## Environment Policy

- All investigations, bug reproductions, Rails commands, and validation of changes must be performed using the `test` environment unless I explicitly request a different environment.
- Never use the `development` database to reproduce bugs or validate changes.
- The `development` database may only be used to run database migrations.
- Always prefer commands with `RAILS_ENV=test`.

---

### Commits

Only create a git commit when the user explicitly asks. When committing, follow `.cursor/rules/commit-patterns.mdc` (Conventional Commits).

---

## Before Writing Code

Ask yourself:

1. Which `.cursor/rules/` apply?
2. Which layer owns this change (see Layer map)?
3. Which existing files are the best reference to mirror?
4. Are there security concerns (auth, tokens, cookies)?
5. Are there performance concerns?
6. Does this require request specs / factories?
7. Does this require OpenAPI / I18n updates?
8. Did the user ask for a commit?

Only then implement.
