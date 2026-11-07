# Projects verification

**Verdict**: FAIL
**Proofs**: `proofs.md` at d54d038
**Verifier**: independent sub-agent (author != verifier)

## Checks

| Check | Test | Holds |
| --- | --- | --- |
| C1 | `spec/requests/api/v1/projects/create_spec.rb` `creates the project owned by the current user with favorite false` | yes |
| C2 | `create_spec.rb` `stores a JPEG or PNG cover image and returns a URL that serves it` | yes - both formats, follows the URL and compares bytes |
| C3 | `create_spec.rb` `rejects a request missing name, client name, start date and end date with an error on each` | yes |
| C4 | `create_spec.rb` `rejects a date that is not a valid date` | yes - loose: `be_present` on `start_date` only; `end_date` is not tried |
| C5 | `create_spec.rb` `rejects an end date before the start date` | yes - exact message |
| C6 | `create_spec.rb` `rejects a cover image that is neither JPEG nor PNG` | yes - GIF and a text file declared `image/png` |
| C7 | `create_spec.rb` `rejects a cover image larger than 5 MB` | yes - 5 MB + 1 rejected, exactly 5 MB accepted |
| C8 | `create_spec.rb` `rejects a name or client name longer than 255 characters` | yes - 256 rejected per field, 255 accepted; error is `be_present` but the only rule a two-word 256-char value can break is length |
| C9 | `create_spec.rb` `ignores favorite sent on create` | yes |
| C10 | `create_spec.rb` `strips surrounding spaces from name and client name` | yes |
| C11 | `create_spec.rb` `rejects a project name with fewer than two words` | yes - exact message, `"Website"` and `"  Website  "` |
| C12 | `create_spec.rb` `rejects a start date before today` | yes - exact message |
| C13 | `create_spec.rb` `rejects an end date before today` | yes - `include` of the `before_today` message (the `before_start_date` error also fires) |
| C14 | `create_spec.rb` `accepts start and end dates equal to today` | yes |
| C15 | `create_spec.rb` `uses today in America/Sao_Paulo` | yes - at 01:00 UTC a UTC "today" would reject 2026-11-05 |
| C16 | `spec/requests/api/v1/projects/show_spec.rb` `returns the project's id, name, client name, dates, favorite and cover image URL` | yes - `eq` on the whole attributes hash |
| C17 | `spec/requests/api/v1/projects/update_spec.rb` `ignores favorite sent on update` | yes |
| C18 | `update_spec.rb` `updates only the fields sent and keeps the rest` | yes - checks client, dates and the same blob id |
| C19 | `update_spec.rb` `replaces the previous cover image` | yes - old blob purged with jobs performed |
| C20 | `update_spec.rb` `rejects an end date before the start date and keeps the project unchanged` | yes |
| C21 | `update_spec.rb` `rejects a changed date before today and keeps the project unchanged` | yes - both fields |
| C22 | `update_spec.rb` `accepts an update that keeps a start date already before today` | yes - with and without the past date sent back |
| C23 | `spec/requests/api/v1/projects/destroy_spec.rb` `deletes the project and its cover image` | yes - project, attachment and blob gone |
| C24 | `spec/requests/api/v1/projects/index_spec.rb` `returns only the current user's projects` | yes |
| C25 | `index_spec.rb` `orders by name ascending ignoring case by default` | yes - a case-sensitive order or a missing id tie-break fails it |
| C26 | `index_spec.rb` `orders by start date descending with sort=recent_start` | yes |
| C27 | `index_spec.rb` `orders by end date ascending with overdue projects first with sort=nearest_deadline` | yes |
| C28 | `index_spec.rb` `breaks ties by name then id` | yes - case-insensitive name tie-break and id order of twins |
| C29 | `index_spec.rb` `rejects an unknown sort value` | yes - loose: `be_present` on `details.sort` |
| C30 | `index_spec.rb` `returns at most 20 projects per page with the pagination block` | yes - `eq` on names and the whole pagination block |
| C31 | `index_spec.rb` `returns the requested page` | yes |
| C32 | `index_spec.rb` `returns an empty list beyond the last page` | yes |
| C33 | `index_spec.rb` `returns an empty list when the user has no projects` | yes |
| C34 | `spec/requests/api/v1/projects/search_spec.rb` `returns projects whose name or client name contains the term` | yes - `contain_exactly`, excludes a foreign match |
| C35 | `search_spec.rb` `matches ignoring letter case` | yes |
| C36 | `search_spec.rb` `matches ignoring accents` | yes - accent on the data side and on the term side |
| C37 | `search_spec.rb` `rejects a search with fewer than 3 characters` | yes - loose: `be_present` on `details.search` |
| C38 | `search_spec.rb` `returns every project when search is blank` | yes |
| C39 | `search_spec.rb` `returns the filtered projects in the chosen order` | yes |
| C40 | `search_spec.rb` `treats % and _ as literal characters` | yes |
| C41 | `spec/requests/api/v1/project/favorites_spec.rb` `marks the project as favorite` | yes |
| C42 | `favorites_spec.rb` `unmarks the project as favorite` | yes |
| C43 | `favorites_spec.rb` `keeps favorite true when already favorited` | yes - a toggle would fail it |
| C44 | `favorites_spec.rb` `keeps favorite false when not favorited` | yes - a toggle would fail it |
| C45 | `favorites_spec.rb` `changes no field other than favorite` | yes |
| C46 | `spec/requests/api/v1/projects/access_spec.rb` `answers 404 on every project endpoint for a missing or another user's project` | yes - all five member endpoints, both ids, foreign project untouched |
| C47 | `access_spec.rb` `answers 401 on every project endpoint without a valid session token` | yes - all seven endpoints |
| C48 | `spec/requests/api/v1/projects/create_spec.rb` `treats non-ASCII spaces as word separators and strips them` | yes - added by the author after finding 2; asserts the stored name and client name exactly (judged by the author, not the Verifier) |

## Findings

| Finding | Evidence | Fix | Closed |
| --- | --- | --- | --- |
| OpenAPI documents the project resource `type` as `project`, but the API returns `"type": ""`; no test asserts it | `public/openapi/components/schemas.yml` `ProjectResource.data.type` `const: project` and the `type: project` example in `public/openapi/paths/project/projects.yml`; a probe `GET /api/v1/projects` returned `"type":""` (`Project::Serializer` has no `set_type`; `User::Serializer` has the same existing gap) | add `set_type :project` to `Project::Serializer` and assert `data.project.data.type` in C16's test, or document the real value | uncommitted working tree (user: "sem commitar nada") - `set_type :project` in `Project::Serializer`; C16's test now asserts `type` is `project` |
| Non-ASCII whitespace slips past the strip and word rules: `"App Mobile"` is rejected as one word, and `search="ab "` passes the 3-character minimum | throwaway probe at the current tree: create answered 422 `name: must have at least two words`; list answered 200. `String#strip`/`#split` only handle ASCII whitespace (`app/models/project/validations.rb:24,29`, `app/models/project/search.rb:23`). Low severity | strip and split on `/[[:space:]]+/` (or `squish`) in `normalize_names`, `name_has_two_words` and `normalize_search`, with a request example for each | uncommitted working tree (user: "sem commitar nada") - `Project::Text` strips/splits on `[[:space:]]`; proven by C48 and by C37's test (`"ac\u00A0"`, `"\u2003ac"` answer 422) |
