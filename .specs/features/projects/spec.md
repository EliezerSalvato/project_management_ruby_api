# Projects Specification

**Approved**: 2026-11-05 - user: "Aprovado, pode seguir."

## Problem Statement

Users of the API have nothing to manage yet beyond their own account. They need to register the projects they work on - name, client, start and end dates, a cover image - list them in a useful order, find one by project or client name, and mark favorites from a separate screen.

## Goals

- [ ] An authenticated user can create, list, show, update and delete their own projects through `/api/v1/projects`.
- [ ] An authenticated user can favorite and unfavorite a project through its own endpoint, `/api/v1/projects/:id/favorite`.
- [ ] The list sorts alphabetically by default, or by most recently started, or by nearest deadline, and filters by a search of at least 3 characters over project name and client name.

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
| ------- | ------ |
| Client entity with its own CRUD | user: "Texto no projeto" - client is a string on the project |
| Sharing projects between users, teams, roles | user: "Do usuário criador" - projects are private to their creator |
| Filtering the list by favorites only, or pinning favorites on top | Not requested; favorite is a flag the list returns |
| Removing the cover image without replacing it | Not requested; an update with a new image replaces the old one |
| Image resizing, thumbnails, variants | Not requested; the original upload is served |
| Soft delete / archiving | Not requested; delete is permanent |
| Cover image formats other than JPEG and PNG | user: "aceitar apenas jpg e png" |

---

## Assumptions & Open Questions

Every ambiguity is resolved or recorded here - nothing is left silently unclear.

| Assumption / decision | Chosen default | Rationale | Confirmed? |
| --------------------- | -------------- | --------- | ---------- |
| Who owns a project | The user who created it; another user's project answers 404 | user: "Do usuário criador" | y |
| How the client is stored | `client_name` string on the project | user: "Texto no projeto" | y |
| How the cover image arrives | `multipart/form-data` upload stored with Active Storage; response carries the image URL | user: "Upload via Active Storage, aceitar apenas jpg e png" | y |
| Accepted cover formats | `image/jpeg` and `image/png` only | user: "aceitar apenas jpg e png" | y |
| Search shorter than 3 characters | 422 with an error on `search`; an absent or blank `search` lists everything | user: "Retorna 422 com erro" | y |
| Required fields and date rule | name, client, start date and end date required; end date on or after start date; dates may be earlier than today; cover optional; favorite starts `false` and is ignored on create/update | user: "Nome, cliente e datas" | y |
| Project name word count | At least two words: after stripping, the name splits on whitespace into 2 or more parts (`App Mobile` passes, `App` fails) | user: "nome do projeto ter pelo menos duas palavras" | y |
| Which "today" | Today (used by the sort orders) in `America/Sao_Paulo`, set as the app's `config.time_zone` | user: "America/Sao_Paulo" | y |
| Nearest-deadline sort | `end_date` ascending over all projects, overdue (end date before today) last; `recent_start`: started (newest first), then upcoming (soonest first), then overdue | user: "Data de fim crescente"; later: "deixar para o final os projetos com prazo que já passou" | y |
| Favorite endpoint shape | `POST /api/v1/projects/:id/favorite` marks, `DELETE` unmarks, both idempotent, both answer 200 with the project | user: "POST/DELETE /favorite" | y |
| Search comparison | Partial match, case- and accent-insensitive (Postgres `unaccent`) | user: "Sem maiúsc. e sem acento" | y |
| Cover image size limit | At most 5 MB; larger answers 422 | Keeps storage bounded; a common limit for cover images | n |
| Sort parameter | `sort=name` (default), `sort=recent_start`, `sort=nearest_deadline`; any other value answers 422 | An unknown value is a client bug better surfaced than ignored | n |
| Tie-breaking inside a sort | Ties broken by name ascending, then id | Gives a stable order across pages | n |
| Alphabetical comparison | Case-insensitive on project name | "alpha" and "Alpha" sit together | n |
| Pagination | Cursor (keyset) for infinite scroll: `after` param with the last loaded project id, 20 items per page, `pagination` block (next, count, limit) in the response | AGENTS.md requires Pagy for collections | n |
| Project name and client length | Each at most 255 characters, surrounding spaces stripped | Matches a `string` column and the profile form's stripping | n |
| Name uniqueness | Not unique | Not requested | n |
| Deleting a project | Permanent; its cover image is purged | No archive was requested | n |
| Update semantics | `PATCH` with partial fields; the same validations apply to the result | Matches the profile update endpoint | n |

**Open questions:** none - all resolved or logged above (required before the spec is confirmed).

---

## User Stories

### P1: Manage my projects ⭐ MVP

**User Story**: As an authenticated user, I want to create, view, update and delete projects so that I keep track of the work I do for each client.

**Why P1**: Without projects there is nothing to list, search or favorite.

**Acceptance Criteria** (each line is one EARS pattern):

1. WHEN an authenticated user sends `POST /api/v1/projects` with name, client name, start date and end date THEN the system SHALL create the project owned by that user and answer 201 with the project, `favorite: false`.
2. WHEN an authenticated user sends `POST /api/v1/projects` with a JPEG or PNG `cover_image` THEN the system SHALL store the image and answer 201 with a `cover_image_url` that serves it.
3. IF the create request lacks name, client name, start date or end date THEN the system SHALL answer 422 with an error on each missing field.
4. IF the end date is before the start date THEN the system SHALL answer 422 with an error on `end_date`.
5. IF the cover image is neither JPEG nor PNG THEN the system SHALL answer 422 with an error on `cover_image`.
6. IF the cover image is larger than 5 MB THEN the system SHALL answer 422 with an error on `cover_image`.
7. IF name or client name exceeds 255 characters THEN the system SHALL answer 422 with an error on that field.
8. WHEN a create or update request sends `favorite` THEN the system SHALL ignore it and leave the favorite flag unchanged.
9. WHEN an authenticated user sends `GET /api/v1/projects/:id` for a project they own THEN the system SHALL answer 200 with the project's id, name, client name, start date, end date, favorite and cover image URL.
10. WHEN an authenticated user sends `PATCH /api/v1/projects/:id` with some fields for a project they own THEN the system SHALL update those fields, keep the rest, and answer 200 with the project.
11. WHEN an update sends a new `cover_image` THEN the system SHALL replace the previous image.
12. IF an update leaves the end date before the start date THEN the system SHALL answer 422 with an error on `end_date` and keep the project unchanged.
13. WHEN an authenticated user sends `DELETE /api/v1/projects/:id` for a project they own THEN the system SHALL delete the project and its cover image and answer 200.
14. IF a user requests show, update, delete, favorite or unfavorite for a project that does not exist or belongs to another user THEN the system SHALL answer 404.
15. IF a request to any `/api/v1/projects` endpoint has no valid session token THEN the system SHALL answer 401.
16. The system SHALL strip surrounding spaces from name and client name before validating and saving them.
17. IF the project name has fewer than two whitespace-separated words THEN the system SHALL answer 422 with an error on `name`.
23. The system SHALL compute today in the `America/Sao_Paulo` time zone for the date-based sort orders.
24. WHEN an update sends `remove_cover_image=true` without a new `cover_image` THEN the system SHALL remove the project's cover image, delete the stored file, keep the other fields, and answer 200 with `cover_image_url: null`; on a project without a cover image it SHALL answer 200.
25. WHEN an update sends both a new `cover_image` and `remove_cover_image=true` THEN the system SHALL store the new image; WHEN `remove_cover_image` is `false`, blank or absent THEN the system SHALL keep the current image; a create request SHALL ignore `remove_cover_image`.

**Independent Test**: Create a project with a two-word name, today's start date and a PNG cover, fetch it, change its end date, delete it; another user's token gets 404 on the same id.

---

### P1: List my projects in a chosen order ⭐ MVP

**User Story**: As an authenticated user, I want my projects listed alphabetically, by most recently started or by nearest deadline so that I find what matters on the list screen.

**Why P1**: The list is the main screen; the user stated all three orders.

**Acceptance Criteria**:

1. WHEN an authenticated user sends `GET /api/v1/projects` THEN the system SHALL answer 200 with only the projects that user owns.
2. WHEN the list request has no `sort` THEN the system SHALL order projects by name ascending, ignoring case.
3. WHEN the list request has `sort=recent_start` THEN the system SHALL list first the projects already started (start date up to today, not overdue) by start date descending, then the projects not started yet (start date after today) by start date ascending, then the overdue projects (end date before today) by start date descending.
4. WHEN the list request has `sort=nearest_deadline` THEN the system SHALL order projects by end date ascending, overdue projects (end date before today) last.
5. WHEN two projects tie on the sort key THEN the system SHALL order them by name ascending, then by id.
6. IF `sort` is any value other than `name`, `recent_start` or `nearest_deadline` THEN the system SHALL answer 422 with an error on `sort`.
7. The system SHALL return at most 20 projects per page and a `pagination` block with `next` (the id to send as `after` for the following projects, `null` on the last page), the total count matching the filters and items per page.
8. WHEN the list request has `after=<id>` THEN the system SHALL return the projects that follow that project in the chosen order; IF the id is not one of the user's projects THEN it SHALL answer 422.
9. WHEN the list request has `favorite=true` THEN the system SHALL return only the user's favorite projects; WHEN it has `favorite=false` THEN only the non-favorite ones; WHEN it is omitted or blank THEN both; the filter SHALL combine with search, sort and after.
10. WHEN the list request has a `favorite` value other than `true` or `false` THEN the system SHALL respond 422 with an error on `favorite`.

**Independent Test**: Create projects with distinct names and dates, call the list with each `sort` value and compare the id order.

---

### P1: Search my projects ⭐ MVP

**User Story**: As an authenticated user, I want to search by project name or client name so that I find a project without scrolling.

**Why P1**: The user stated the search and its 3-character minimum.

**Acceptance Criteria**:

1. WHEN the list request has `search` of 3 or more characters THEN the system SHALL return only the user's projects whose name or client name contains the term.
2. The system SHALL match the search term ignoring letter case.
3. The system SHALL match the search term ignoring accents, so `sao` finds `São Paulo`.
4. IF `search`, after stripping surrounding spaces, has 1 or 2 characters THEN the system SHALL answer 422 with an error on `search`.
5. WHEN `search` is absent or blank THEN the system SHALL return the list unfiltered.
6. WHEN the list request has both `search` and `sort` THEN the system SHALL return the filtered projects in the chosen order.
7. The system SHALL treat `%` and `_` in the search term as literal characters.

**Independent Test**: Create "Café Mobile" for client "Acme" and "Site" for client "São Paulo FC"; `search=cafe` returns the first, `search=sao` the second, `search=ac` answers 422.

---

### P1: Favorite and unfavorite a project ⭐ MVP

**User Story**: As an authenticated user, I want to mark and unmark a project as favorite from a separate screen so that I can flag the ones I care about.

**Why P1**: The user asked for it as its own endpoint.

**Acceptance Criteria**:

1. WHEN an authenticated user sends `POST /api/v1/projects/:id/favorite` for a project they own THEN the system SHALL set `favorite` to true and answer 200 with the project.
2. WHEN an authenticated user sends `DELETE /api/v1/projects/:id/favorite` for a project they own THEN the system SHALL set `favorite` to false and answer 200 with the project.
3. WHEN a project already favorited receives `POST .../favorite` THEN the system SHALL answer 200 with `favorite: true`.
4. WHEN a project not favorited receives `DELETE .../favorite` THEN the system SHALL answer 200 with `favorite: false`.
5. The system SHALL change no project field other than `favorite` through the favorite endpoints.

**Independent Test**: POST favorite twice, then DELETE twice, checking `favorite` after each call.

---

## Edge Cases

- IF `after` is the last project THEN the system SHALL answer 200 with an empty list and `next` null.
- IF the start date or end date is not a valid date THEN the system SHALL answer 422 with an error on that field (covered by MGMT-03).
- WHEN the user has no projects THEN the system SHALL answer 200 with an empty list and `count: 0`.

---

## Requirement Traceability

| Requirement ID | Story | Phase | Status |
| -------------- | ----- | ----- | ------ |
| MGMT-01 | P1: Manage - create | Execute | Verified |
| MGMT-02 | P1: Manage - cover upload | Execute | Verified |
| MGMT-03 | P1: Manage - required fields and valid dates | Execute | Verified |
| MGMT-04 | P1: Manage - end date after start date | Execute | Verified |
| MGMT-05 | P1: Manage - cover format | Execute | Verified |
| MGMT-06 | P1: Manage - cover size | Execute | Verified |
| MGMT-07 | P1: Manage - length limits | Execute | Verified |
| MGMT-08 | P1: Manage - favorite ignored on create/update | Execute | Verified |
| MGMT-09 | P1: Manage - show | Execute | Verified |
| MGMT-10 | P1: Manage - partial update | Execute | Verified |
| MGMT-11 | P1: Manage - cover replace | Execute | Verified |
| MGMT-12 | P1: Manage - update date rule | Execute | Verified |
| MGMT-13 | P1: Manage - delete | Execute | Verified |
| MGMT-14 | P1: Manage - 404 for missing / foreign | Execute | Verified |
| MGMT-15 | P1: Manage - 401 without token | Execute | Verified |
| MGMT-16 | P1: Manage - strip spaces | Execute | Verified |
| MGMT-17 | P1: Manage - name has two words | Execute | Verified |
| MGMT-23 | P1: Manage - today in America/Sao_Paulo | Execute | Verified |
| MGMT-24 | P1: Manage - remove cover image on update | Execute | Verified |
| MGMT-25 | P1: Manage - remove flag vs upload, false, create | Execute | Verified |
| LIST-01 | P1: List - own projects only | Execute | Verified |
| LIST-02 | P1: List - default alphabetical | Execute | Verified |
| LIST-03 | P1: List - recent start | Execute | Verified |
| LIST-04 | P1: List - nearest deadline | Execute | Verified |
| LIST-05 | P1: List - tie-break | Execute | Verified |
| LIST-06 | P1: List - invalid sort | Execute | Verified |
| LIST-07 | P1: List - page size and pagination block | Execute | Verified |
| LIST-08 | P1: List - after cursor | Execute | Verified |
| LIST-09 | P1: List - favorite filter | Execute | Verified |
| LIST-10 | P1: List - invalid favorite value | Execute | Verified |
| SRCH-01 | P1: Search - name or client | Execute | Verified |
| SRCH-02 | P1: Search - case-insensitive | Execute | Verified |
| SRCH-03 | P1: Search - accent-insensitive | Execute | Verified |
| SRCH-04 | P1: Search - minimum 3 characters | Execute | Verified |
| SRCH-05 | P1: Search - blank lists all | Execute | Verified |
| SRCH-06 | P1: Search - combined with sort | Execute | Verified |
| SRCH-07 | P1: Search - wildcards literal | Execute | Verified |
| FAV-01 | P1: Favorite - mark | Execute | Verified |
| FAV-02 | P1: Favorite - unmark | Execute | Verified |
| FAV-03 | P1: Favorite - mark idempotent | Execute | Verified |
| FAV-04 | P1: Favorite - unmark idempotent | Execute | Verified |
| FAV-05 | P1: Favorite - changes nothing else | Execute | Verified |

**ID format:** `[CATEGORY]-[NUMBER]`

**Status values:** Pending → In Design → In Tasks → Implementing → Verified

**Coverage:** 42 total, 42 mapped to tasks, 0 unmapped

---

## Sources

- User request (2026-11-05) - fields, separate favorite endpoint, three sort orders, search with a 3-character minimum.
- User adjustment (2026-11-05) - project name of at least two words.
- User adjustment (2026-11-08) - removed the rule that dates may not be earlier than today.
- `.specs/features/projects/context.md` - answers to the gray areas.
- `AGENTS.md` - Pagy for collections, form objects, serializers, I18n, OpenAPI.

---

## Success Criteria

- [ ] Every criterion above has a request spec that passes in `docker compose exec api bin/rspec`.
- [ ] `/docs` documents all seven project endpoints.
