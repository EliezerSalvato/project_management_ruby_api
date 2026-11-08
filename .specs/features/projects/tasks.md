# Projects Tasks

## Execution Protocol (MANDATORY -- do not skip)

Implement these tasks with the `tlc-spec-driven` skill: **activate it by name and follow its Execute flow and Critical Rules.** Do not search for skill files by filesystem path. The skill is the source of truth for the full flow (per-task cycle, sub-agent delegation, the walk, check_proofs, the Verifier and the screens sub-agent).

**If the skill cannot be activated, STOP and tell the user - do not proceed without it.**

---

**Design**: `.specs/features/projects/design.md`
**Status**: Done - uncommitted (user: "sem commitar nada")
**Approved**: 2026-11-05 - user: "Aprovado, pode seguir, mas sem commitar nada"
**Build**: `docker compose exec -T api bin/rubocop; docker compose exec -T api bundle exec i18n-tasks missing; docker compose exec -T api bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error; docker compose exec -T api bin/rspec`
**Run req**: `docker compose exec -T api bash -c 'bin/rspec spec/requests/api/v1/projects spec/requests/api/v1/project --format json --out tmp/proof.json > /dev/null 2>&1; ruby -rjson -e "JSON.parse(File.read(%q(tmp/proof.json)))[%q(examples)].each { puts it[%q(status)].upcase + %q( ) + it[%q(full_description)] }"'`

---

## Test Coverage Matrix

> Generated from codebase, project guidelines, and spec - confirm before Execute. Guidelines found: `AGENTS.md` (Tests), `.cursor/rules/spec-patterns.mdc`, `spec/spec_helper.rb` (SimpleCov minimum 80% line / 50% branch), `config/ci.rb`.

| Code Layer | Required Test Type | Coverage Expectation | Location Pattern | Run Command |
| ---------- | ------------------ | -------------------- | ---------------- | ----------- |
| Controller + forms + scopes (endpoint) | request (integration) | Every route: happy path, each AC, each edge case, 401 via `"an unauthorized API request"`, 404 for missing/foreign ids | `spec/requests/api/v1/projects/*_spec.rb`, `spec/requests/api/v1/project/*_spec.rb` | `docker compose exec -T api bin/rspec` |
| Active Record (`Project`) | model | Association and `dependent:` behavior only | `spec/models/project_spec.rb` | `docker compose exec -T api bin/rspec` |
| Form error keys | model (`error_messages_spec`) | Every `errors.add` key translated in `en` and `pt-BR` | `spec/models/user/error_messages_spec.rb` | `docker compose exec -T api bin/rspec` |
| Migrations / config / OpenAPI | none | Build gate only | `db/migrate/`, `config/`, `public/openapi/` | build gate only |

## Gate Check Commands

> Generated from codebase - confirm before Execute. A single-file run trips SimpleCov's minimum coverage, so every gate runs the whole suite.

| Gate Level | When to Use | Command |
| ---------- | ----------- | ------- |
| Quick | Not used (SimpleCov minimum fails partial runs) | - |
| Full | After any task with tests | `docker compose exec -T api bin/rspec` |
| Build | After config / migration / docs tasks, and after each phase | `docker compose exec -T api bin/rubocop; docker compose exec -T api bundle exec i18n-tasks missing; docker compose exec -T api bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error; docker compose exec -T api bin/rspec` |

---

## Execution Plan

Phases are ordered and run sequentially - each phase completes before the next begins, and tasks within a phase execute in order.

### Phase 1: Foundation

```
T1 → T2 → T3 → T4
```

### Phase 2: Project CRUD

```
T5 → T6 → T7 → T8
```

### Phase 3: List, sort and search

```
T9 → T10
```

### Phase 4: Favorite and docs

```
T11 → T12
```

---

## Task Breakdown

### T1: Set the app time zone to America/Sao_Paulo ✅

**What**: Set `config.time_zone = "America/Sao_Paulo"` so `Date.current` is Brasília's today.
**Where**: `config/application.rb`
**Depends on**: None
**Reuses**: -
**Requirement**: MGMT-23

**Done when**:

- [x] `docker compose exec -T api bin/rails runner -e test 'puts Time.zone.name'` prints `America/Sao_Paulo`
- [x] Build gate passes; test count stays 137

**Tests**: none
**Gate**: build

**Commit**: `chore(config): set time zone to America/Sao_Paulo`

---

### T2: Install the Active Storage tables ✅

**What**: Run `bin/rails active_storage:install`, migrate (development and test), commit the migration and `db/schema.rb`; tables use UUID keys.
**Where**: `db/migrate/*_create_active_storage_tables.active_storage.rb`
**Depends on**: T1
**Reuses**: generator config `primary_key_type: :uuid`
**Requirement**: MGMT-02

**Done when**:

- [x] `db/schema.rb` has `active_storage_blobs`, `active_storage_attachments` (`record_id` uuid), `active_storage_variant_records`
- [x] Build gate passes; test count stays 137

**Tests**: none
**Gate**: build

**Commit**: `chore(db): install active storage tables`

---

### T3: Create the projects table and enable unaccent ✅

**What**: Migration enabling `unaccent` and creating `projects` as in design.md Data Models.
**Where**: `db/migrate/*_create_projects.rb`
**Depends on**: T2
**Reuses**: `db/migrate/20261105130401_create_user_sessions.rb`
**Requirement**: MGMT-01, SRCH-03

**Done when**:

- [x] `db/schema.rb` has `enable_extension "unaccent"` and the `projects` table with `null: false` on name, client_name, dates, favorite (default false) and an index on `user_id`
- [x] Build gate passes; test count stays 137

**Tests**: none
**Gate**: build

**Commit**: `feat(db): create projects table`

---

### T4: Add the Project record, association and factory ✅

**What**: `Project` (`belongs_to :user`, `has_one_attached :cover_image`), `User has_many :projects, dependent: :destroy`, factory `:project` (two-word name, today's start date, end date 30 days later, trait `:with_cover_image`), PNG/JPEG fixtures, and a thin model spec.
**Where**: `app/models/project.rb`
**Depends on**: T3
**Reuses**: `app/models/user_session.rb`, `spec/factories/user/sessions.rb`
**Requirement**: MGMT-01

**Done when**:

- [x] `spec/models/project_spec.rb`: a project belongs to a user; destroying the user destroys their projects
- [x] Files: `app/models/user.rb`, `spec/factories/project/projects.rb`, `spec/fixtures/files/cover.png`, `spec/fixtures/files/cover.jpg`, `spec/fixtures/files/cover.gif`
- [x] Full gate passes; test count 137 + new model examples

**Tests**: model
**Gate**: full

**Commit**: `feat(project): add project record`

---

### T5: Create a project (POST /api/v1/projects) ✅

**What**: Route, `API::V1::ProjectsController#create`, `Project::Creation`, `Project::Validations`, `Project::Sort`/`Project::CoverImage` constants (cover only), `Project::Serializer`, `default_url_options` initializer, locales `config/locales/project/{en,pt-BR}.yml`, extend `error_messages_spec` to `app/models/project/**`.
**Where**: `app/models/project/creation.rb`
**Depends on**: Phase 1 (runs after it completes)
**Reuses**: `User::Registration`, `User::Profile::Update`, `API::V1::User::RegistrationsController`
**Requirement**: MGMT-01, MGMT-02, MGMT-03, MGMT-04, MGMT-05, MGMT-06, MGMT-07, MGMT-08, MGMT-16, MGMT-17, MGMT-23, MGMT-15, MGMT-24, MGMT-25

**Done when**:

- [x] `spec/requests/api/v1/projects/create_spec.rb` (`RSpec.describe "POST /api/v1/projects"`) has the tests C1-C11 name, plus `it_behaves_like "an unauthorized API request"`
- [x] `error_messages_spec` scans `app/models/project/**` and passes in `en` and `pt-BR`
- [x] Full gate passes; no test removed

**Tests**: request
**Gate**: full

**Commit**: `feat(project): create projects`

---

### T6: Show a project (GET /api/v1/projects/:id) and answer 404 ✅

**What**: `ProjectsController#show` via `current_user.projects.find`; `rescue_from ActiveRecord::RecordNotFound` → 404 in `BaseController` with `api.errors.not_found` (`config/locales/api/{en,pt-BR}.yml`).
**Where**: `app/controllers/api/v1/projects_controller.rb` (modify)
**Depends on**: T5
**Reuses**: `render_json_with_error`
**Requirement**: MGMT-09, MGMT-14

**Done when**:

- [x] `spec/requests/api/v1/projects/show_spec.rb` (`RSpec.describe "GET /api/v1/projects/:id"`) has C16, a 404 for another user's project and for a missing id, and the 401 shared example
- [x] Full gate passes; no test removed

**Tests**: request
**Gate**: full

**Commit**: `feat(project): show a project`

---

### T7: Update a project (PATCH /api/v1/projects/:id) ✅

**What**: `ProjectsController#update` and `Project::Update` (given keys only, fill the rest from the project).
**Where**: `app/models/project/update.rb`
**Depends on**: T6
**Reuses**: `Project::Validations`, `User::Profile::Update`
**Requirement**: MGMT-08, MGMT-10, MGMT-11, MGMT-12

**Done when**:

- [x] `spec/requests/api/v1/projects/update_spec.rb` (`RSpec.describe "PATCH /api/v1/projects/:id"`) has C17-C20, a 404 for another user's project, and the 401 shared example
- [x] Full gate passes; no test removed

**Tests**: request
**Gate**: full

**Commit**: `feat(project): update a project`

---

### T8: Delete a project (DELETE /api/v1/projects/:id) ✅

**What**: `ProjectsController#destroy` → `project.destroy!`, 200 with `project.deletion.success`.
**Where**: `app/controllers/api/v1/projects_controller.rb` (modify)
**Depends on**: T7
**Reuses**: `API::V1::User::Session::RevokesController`
**Requirement**: MGMT-13

**Done when**:

- [x] `spec/requests/api/v1/projects/destroy_spec.rb` (`RSpec.describe "DELETE /api/v1/projects/:id"`) has C23, a 404 for another user's project, and the 401 shared example
- [x] Full gate passes; no test removed

**Tests**: request
**Gate**: full

**Commit**: `feat(project): delete a project`

---

### T9: List projects with sort and pagination (GET /api/v1/projects) ✅

**What**: `ProjectsController#index`, `Project::Search` (sort rule only), `Project::Sort`, `Project.sorted_by`, `include Pagy::Method` in `BaseController`, `pagination` block.
**Where**: `app/models/project/search.rb`
**Depends on**: Phase 2 (runs after it completes)
**Reuses**: Pagy 43 `pagy(:offset, ...)`, `render_json_with_model_errors`
**Requirement**: LIST-01, LIST-02, LIST-03, LIST-04, LIST-05, LIST-06, LIST-07, LIST-08, LIST-09, LIST-10

**Done when**:

- [x] `spec/requests/api/v1/projects/index_spec.rb` (`RSpec.describe "GET /api/v1/projects"`) has C24-C33 and the 401 shared example
- [x] Full gate passes; no test removed

**Tests**: request
**Gate**: full

**Commit**: `feat(project): list projects with sort and pagination`

---

### T10: Search projects by name or client ✅

**What**: `Project.search` scope (unaccent + ILIKE + `sanitize_sql_like`) and the `search` rule on `Project::Search`.
**Where**: `app/models/project.rb` (modify)
**Depends on**: T9
**Reuses**: `Project::Search` from T9
**Requirement**: SRCH-01, SRCH-02, SRCH-03, SRCH-04, SRCH-05, SRCH-06, SRCH-07

**Done when**:

- [x] `spec/requests/api/v1/projects/search_spec.rb` (`RSpec.describe "GET /api/v1/projects with search"`) has C34-C40
- [x] Full gate passes; no test removed

**Tests**: request
**Gate**: full

**Commit**: `feat(project): search projects by name or client`

---

### T11: Favorite and unfavorite (POST/DELETE /api/v1/projects/:project_id/favorite) ✅

**What**: Nested route, `API::V1::Project::FavoritesController#create/#destroy`, and the cross-endpoint access spec (401 and 404 on all seven endpoints).
**Where**: `app/controllers/api/v1/project/favorites_controller.rb`
**Depends on**: Phase 3 (runs after it completes)
**Reuses**: `current_user.projects.find`, `Project::Serializer`
**Requirement**: FAV-01, FAV-02, FAV-03, FAV-04, FAV-05, MGMT-14, MGMT-15

**Done when**:

- [x] `spec/requests/api/v1/project/favorites_spec.rb` (`RSpec.describe "Project favorites"`) has C41-C45 and the 401 shared example
- [x] `spec/requests/api/v1/projects/access_spec.rb` (`RSpec.describe "Project endpoints access"`) has C46-C47
- [x] Full gate passes; no test removed

**Tests**: request
**Gate**: full

**Commit**: `feat(project): favorite and unfavorite projects`

---

### T12: Document the project endpoints in OpenAPI ✅

**What**: Path files for `/api/v1/projects`, `/api/v1/projects/{id}`, `/api/v1/projects/{project_id}/favorite`; `Project`, request and list schemas; a `Projects` tag; `NotFound` response; wired in `spec.yml`.
**Where**: `public/openapi/paths/project/projects.yml`
**Depends on**: T11
**Reuses**: `public/openapi/paths/user/profiles.yml`, `components/schemas.yml`, `components/responses.yml`
**Requirement**: all (documentation)

**Done when**:

- [x] `spec.yml` references the three path files; every `$ref` resolves (`docker compose exec -T api ruby -ryaml -e` load of each file succeeds)
- [x] Seven operations documented with 200/201, 401, 404, 422 as they apply
- [x] Build gate passes

**Tests**: none
**Gate**: build

**Commit**: `docs(openapi): document project endpoints`

---

## Checks

**C1** - `POST /api/v1/projects` with name, client, dates answers 201 with a project owned by the caller and `favorite: false` (MGMT-01, AC 1)
Proof: run req | PASSED POST /api/v1/projects creates the project owned by the current user with favorite false

**C2** - A JPEG or PNG `cover_image` is stored and `cover_image_url` serves its bytes (MGMT-02, AC 2)
Proof: run req | PASSED POST /api/v1/projects stores a JPEG or PNG cover image and returns a URL that serves it

**C3** - Missing name, client name, start date and end date answers 422 with an error on each of the four (MGMT-03, AC 3)
Proof: run req | PASSED POST /api/v1/projects rejects a request missing name, client name, start date and end date with an error on each

**C4** - A date that is not a valid date answers 422 with an error on that field (MGMT-03, Edge case 2)
Proof: run req | PASSED POST /api/v1/projects rejects a date that is not a valid date

**C5** - End date before start date answers 422 with an error on `end_date` (MGMT-04, AC 4)
Proof: run req | PASSED POST /api/v1/projects rejects an end date before the start date

**C6** - A GIF, or a text file named `.png`, answers 422 with an error on `cover_image` (MGMT-05, AC 5)
Proof: run req | PASSED POST /api/v1/projects rejects a cover image that is neither JPEG nor PNG

**C7** - A cover over 5 MB answers 422 with an error on `cover_image`; exactly 5 MB is accepted (MGMT-06, AC 6)
Proof: run req | PASSED POST /api/v1/projects rejects a cover image larger than 5 MB

**C8** - A 256-character name or client name answers 422 on that field; 255 is accepted (MGMT-07, AC 7)
Proof: run req | PASSED POST /api/v1/projects rejects a name or client name longer than 255 characters

**C9** - `favorite: true` on create is ignored; the project is created with `favorite: false` (MGMT-08, AC 8)
Proof: run req | PASSED POST /api/v1/projects ignores favorite sent on create

**C10** - Surrounding spaces in name and client name are stripped before saving (MGMT-16, AC 16)
Proof: run req | PASSED POST /api/v1/projects strips surrounding spaces from name and client name

**C11** - A one-word name (including `"  App  "`) answers 422 with an error on `name` (MGMT-17, AC 17)
Proof: run req | PASSED POST /api/v1/projects rejects a project name with fewer than two words

**C16** - `GET /api/v1/projects/:id` answers 200 with id, name, client_name, start_date, end_date, favorite and cover_image_url (MGMT-09, AC 9)
Proof: run req | PASSED GET /api/v1/projects/:id returns the project's id, name, client name, dates, favorite and cover image URL

**C17** - `favorite` sent on `PATCH` is ignored and stays as it was (MGMT-08, AC 8)
Proof: run req | PASSED PATCH /api/v1/projects/:id ignores favorite sent on update

**C18** - `PATCH` with only `name` changes the name and keeps client, dates and cover (MGMT-10, AC 10)
Proof: run req | PASSED PATCH /api/v1/projects/:id updates only the fields sent and keeps the rest

**C19** - `PATCH` with a new `cover_image` replaces the blob; the old blob is gone (MGMT-11, AC 11)
Proof: run req | PASSED PATCH /api/v1/projects/:id replaces the previous cover image

**C20** - `PATCH` with an end date before the start date answers 422 on `end_date`; the stored project is unchanged (MGMT-12, AC 12)
Proof: run req | PASSED PATCH /api/v1/projects/:id rejects an end date before the start date and keeps the project unchanged

**C23** - `DELETE /api/v1/projects/:id` answers 200; the project and its attachment are gone (MGMT-13, AC 13)
Proof: run req | PASSED DELETE /api/v1/projects/:id deletes the project and its cover image

**C24** - The list holds only the caller's projects, never another user's (LIST-01, AC 1)
Proof: run req | PASSED GET /api/v1/projects returns only the current user's projects

**C25** - Without `sort`, `"beta App"`, `"Alpha App"`, `"alpha app"`, `"Charlie App"` (created in that order) come back as `Alpha App`, `alpha app`, `beta App`, `Charlie App` - names equal in lowercase fall to the id tie-break (LIST-02, AC 2)
Proof: run req | PASSED GET /api/v1/projects orders by name ascending ignoring case by default

**C26** - `sort=recent_start` orders by start date descending (LIST-03, AC 3)
Proof: run req | PASSED GET /api/v1/projects orders by start date descending with sort=recent_start

**C27** - `sort=nearest_deadline` orders by end date ascending, an overdue project first (LIST-04, AC 4)
Proof: run req | PASSED GET /api/v1/projects orders by end date ascending with overdue projects first with sort=nearest_deadline

**C28** - Projects tied on the sort key come back by name, then by id (LIST-05, AC 5)
Proof: run req | PASSED GET /api/v1/projects breaks ties by name then id

**C29** - `sort=oldest` answers 422 with an error on `sort` (LIST-06, AC 6)
Proof: run req | PASSED GET /api/v1/projects rejects an unknown sort value

**C30** - 21 projects: page 1 holds 20 and `pagination` is `{ page: 1, pages: 2, count: 21, limit: 20 }` (LIST-07, AC 7)
Proof: run req | PASSED GET /api/v1/projects returns at most 20 projects per page with the pagination block

**C31** - `page=2` of 21 projects holds the 21st in the chosen order (LIST-08, AC 8)
Proof: run req | PASSED GET /api/v1/projects returns the requested page

**C32** - `page=5` of 21 projects answers 200 with an empty list and the pagination block (LIST-08, Edge case 1)
Proof: run req | PASSED GET /api/v1/projects returns an empty list beyond the last page

**C33** - A user with no projects gets 200, an empty list and `count: 0` (LIST-07, Edge case 3)
Proof: run req | PASSED GET /api/v1/projects returns an empty list when the user has no projects

**C34** - `search=acm` returns the project whose client is "Acme" and the one named "Acme Portal", not others (SRCH-01, AC 1)
Proof: run req | PASSED GET /api/v1/projects with search returns projects whose name or client name contains the term

**C35** - `search=ACME` finds client "acme corp" (SRCH-02, AC 2)
Proof: run req | PASSED GET /api/v1/projects with search matches ignoring letter case

**C36** - `search=sao` finds client "São Paulo FC" and `search=café` finds "Cafe Mobile" (SRCH-03, AC 3)
Proof: run req | PASSED GET /api/v1/projects with search matches ignoring accents

**C37** - `search=ac` and `search="  ac  "` answer 422 with an error on `search` (SRCH-04, AC 4)
Proof: run req | PASSED GET /api/v1/projects with search rejects a search with fewer than 3 characters

**C38** - `search=""` and `search="   "` return every project (SRCH-05, AC 5)
Proof: run req | PASSED GET /api/v1/projects with search returns every project when search is blank

**C39** - `search` with `sort=nearest_deadline` returns only matches, in end-date order (SRCH-06, AC 6)
Proof: run req | PASSED GET /api/v1/projects with search returns the filtered projects in the chosen order

**C40** - `search=50%` matches "Sale 50% Off" and not "Sale 500 Off"; `search=a_b` matches "a_b App" and not "axb App" (SRCH-07, AC 7)
Proof: run req | PASSED GET /api/v1/projects with search treats % and _ as literal characters

**C41** - `POST .../favorite` answers 200 with `favorite: true` and stores true (FAV-01, AC 1)
Proof: run req | PASSED Project favorites POST /api/v1/projects/:project_id/favorite marks the project as favorite

**C42** - `DELETE .../favorite` answers 200 with `favorite: false` and stores false (FAV-02, AC 2)
Proof: run req | PASSED Project favorites DELETE /api/v1/projects/:project_id/favorite unmarks the project as favorite

**C43** - `POST .../favorite` on a favorited project answers 200 with `favorite: true` (FAV-03, AC 3)
Proof: run req | PASSED Project favorites POST /api/v1/projects/:project_id/favorite keeps favorite true when already favorited

**C44** - `DELETE .../favorite` on a non-favorited project answers 200 with `favorite: false` (FAV-04, AC 4)
Proof: run req | PASSED Project favorites DELETE /api/v1/projects/:project_id/favorite keeps favorite false when not favorited

**C45** - Favorite endpoints sent extra fields (name, dates) change nothing but `favorite` (FAV-05, AC 5)
Proof: run req | PASSED Project favorites changes no field other than favorite

**C46** - Show, update, delete, favorite and unfavorite answer 404 for a missing id and for another user's project (MGMT-14, AC 14)
Proof: run req | PASSED Project endpoints access answers 404 on every project endpoint for a missing or another user's project

**C48** - Non-breaking and other Unicode spaces are stripped from name and client name and separate words: `"\u00A0Website\u00A0Redesign\u2003"` is created as `"Website\u00A0Redesign"` (MGMT-16, AC 16; MGMT-17, AC 17 - Verifier finding 2)
Proof: run req | PASSED POST /api/v1/projects treats non-ASCII spaces as word separators and strips them

**C47** - All seven project endpoints answer 401 without a valid session token (MGMT-15, AC 15)
Proof: run req | PASSED Project endpoints access answers 401 on every project endpoint without a valid session token

---

**C49** - `favorite=true` lists only the user's favorites, `favorite=false` only the others, blank lists both (LIST-09, AC 9)
Proof: run req | PASSED GET /api/v1/projects lists only favorite projects with favorite=true and only the others with favorite=false

**C50** - The favorite filter combines with search and the default sort (LIST-09, AC 9)
Proof: run req | PASSED GET /api/v1/projects combines the favorite filter with search and sort

**C51** - `favorite` values other than `true`/`false` (`yes`, `1`, `TRUE`) answer 422 with `details.favorite` (LIST-10, AC 10)
Proof: run req | PASSED GET /api/v1/projects rejects a favorite value other than true or false

**C52** - `remove_cover_image=true` removes the cover, purges the blob, keeps name and client, answers `cover_image_url: null` (MGMT-24, AC 24)
Proof: run req | PASSED PATCH /api/v1/projects/:id removes the cover image with remove_cover_image=true and keeps the other fields

**C53** - `remove_cover_image: true` in a JSON body removes the cover (MGMT-24, AC 24)
Proof: run req | PASSED PATCH /api/v1/projects/:id removes the cover image with remove_cover_image=true sent as JSON

**C54** - Removing the cover of a project without one answers 200 (MGMT-24, AC 24)
Proof: run req | PASSED PATCH /api/v1/projects/:id answers 200 when removing the cover image of a project without one

**C55** - `remove_cover_image` `false`, blank or absent keeps the same blob (MGMT-25, AC 25)
Proof: run req | PASSED PATCH /api/v1/projects/:id keeps the cover image when remove_cover_image is false or absent

**C56** - A new upload together with `remove_cover_image=true` stores the new JPEG (MGMT-25, AC 25)
Proof: run req | PASSED PATCH /api/v1/projects/:id uses the new upload when cover_image and remove_cover_image=true come together

**C57** - `remove_cover_image=true` on create is ignored and the uploaded cover stays (MGMT-25, AC 25)
Proof: run req | PASSED POST /api/v1/projects ignores remove_cover_image sent on create

## Handoff

The feature's live state, written as it happens - a compaction gives no warning.

**Settled mid-build:** user: "sem commitar nada" - no git commits; every task stays uncommitted in the working tree. Execution inline (no sub-agents) - recommended option, user said "pode seguir".
**Dispatched:** Verifier (round 1) over HEAD d54d038 + uncommitted working tree (user asked for no commits) - returned (2 findings, both fixed in one pass); round 2 = check_proofs.py
**Walked:** API only, no screen - each story's Independent Test is covered by the request specs in proofs.md (no browser walk applies)

---

## Phase Execution Map

```
Phase 1 → Phase 2 → Phase 3 → Phase 4

Phase 1:  T1 ------→ T2 ------→ T3 ------→ T4
Phase 2:  T5 ------→ T6 ------→ T7 ------→ T8
Phase 3:  T9 ------→ T10
Phase 4:  T11 -----→ T12
```

Execution is strictly sequential - there is no intra-phase parallelism.

---

## Task Granularity Check

| Task | Scope | Status |
| ---- | ----- | ------ |
| T1: Time zone | 1 config line | ✅ Granular |
| T2: Active Storage tables | 1 generated migration | ✅ Granular |
| T3: Projects table | 1 migration | ✅ Granular |
| T4: Project record | record + association + factory | ⚠️ Cohesive |
| T5: Create endpoint | 1 endpoint (form, rules, serializer) | ⚠️ Cohesive - first endpoint carries the shared pieces |
| T6: Show endpoint | 1 endpoint + 404 rescue | ✅ Granular |
| T7: Update endpoint | 1 endpoint | ✅ Granular |
| T8: Delete endpoint | 1 endpoint | ✅ Granular |
| T9: Index endpoint | 1 endpoint | ✅ Granular |
| T10: Search | 1 scope + 1 rule | ✅ Granular |
| T11: Favorite endpoints | 1 resource (2 actions) | ✅ Granular |
| T12: OpenAPI | docs | ✅ Granular |

## Diagram-Definition Cross-Check

| Task | Depends On (task body) | Diagram Shows | Status |
| ---- | ---------------------- | ------------- | ------ |
| T1 | None | start | ✅ Match |
| T2 | T1 | T1 → T2 | ✅ Match |
| T3 | T2 | T2 → T3 | ✅ Match |
| T4 | T3 | T3 → T4 | ✅ Match |
| T5 | Phase 1 | Phase 1 → T5 | ✅ Match |
| T6 | T5 | T5 → T6 | ✅ Match |
| T7 | T6 | T6 → T7 | ✅ Match |
| T8 | T7 | T7 → T8 | ✅ Match |
| T9 | Phase 2 | Phase 2 → T9 | ✅ Match |
| T10 | T9 | T9 → T10 | ✅ Match |
| T11 | Phase 3 | Phase 3 → T11 | ✅ Match |
| T12 | T11 | T11 → T12 | ✅ Match |

## Test Co-location Validation

| Task | Code Layer Created/Modified | Matrix Requires | Task Says | Status |
| ---- | --------------------------- | --------------- | --------- | ------ |
| T1 | config | none | none | ✅ OK |
| T2 | migration | none | none | ✅ OK |
| T3 | migration | none | none | ✅ OK |
| T4 | Active Record | model | model | ✅ OK |
| T5-T11 | endpoint | request | request | ✅ OK |
| T12 | OpenAPI | none | none | ✅ OK |
