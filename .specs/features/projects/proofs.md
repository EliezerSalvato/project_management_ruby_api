# projects proofs

**HEAD**: bc9a10c
**Tree**: dirty - app/controllers/api/v1/base_controller.rb, app/models/user.rb, config/application.rb, config/routes.rb, db/schema.rb
**Shell**: /bin/sh
**Result**: 61 pass, 0 fail

| Check | Proof | Result |
| --- | --- | --- |
| C1 | `run req / PASSED POST /api/v1/projects creates the project owned by the current user with favorite false` | pass |
| C2 | `run req / PASSED POST /api/v1/projects stores a JPEG or PNG cover image and returns a URL that serves it` | pass |
| C3 | `run req / PASSED POST /api/v1/projects rejects a request missing name, client name, start date and end date wi` | pass |
| C4 | `run req / PASSED POST /api/v1/projects rejects a date that is not a valid date` | pass |
| C5 | `run req / PASSED POST /api/v1/projects rejects an end date before the start date` | pass |
| C6 | `run req / PASSED POST /api/v1/projects rejects a cover image that is neither JPEG nor PNG` | pass |
| C7 | `run req / PASSED POST /api/v1/projects rejects a cover image larger than 5 MB` | pass |
| C8 | `run req / PASSED POST /api/v1/projects rejects a name or client name longer than 255 characters` | pass |
| C9 | `run req / PASSED POST /api/v1/projects ignores favorite sent on create` | pass |
| C10 | `run req / PASSED POST /api/v1/projects strips surrounding spaces from name and client name` | pass |
| C11 | `run req / PASSED POST /api/v1/projects rejects a project name with fewer than two words` | pass |
| C12 | `run req / PASSED POST /api/v1/projects rejects a start date before today` | pass |
| C13 | `run req / PASSED POST /api/v1/projects rejects an end date before today` | pass |
| C14 | `run req / PASSED POST /api/v1/projects accepts start and end dates equal to today` | pass |
| C15 | `run req / PASSED POST /api/v1/projects uses today in America/Sao_Paulo` | pass |
| C16 | `run req / PASSED GET /api/v1/projects/:id returns the project's id, name, client name, dates, favorite and cov` | pass |
| C17 | `run req / PASSED PATCH /api/v1/projects/:id ignores favorite sent on update` | pass |
| C18 | `run req / PASSED PATCH /api/v1/projects/:id updates only the fields sent and keeps the rest` | pass |
| C19 | `run req / PASSED PATCH /api/v1/projects/:id replaces the previous cover image` | pass |
| C20 | `run req / PASSED PATCH /api/v1/projects/:id rejects an end date before the start date and keeps the project un` | pass |
| C21 | `run req / PASSED PATCH /api/v1/projects/:id rejects a changed date before today and keeps the project unchange` | pass |
| C22 | `run req / PASSED PATCH /api/v1/projects/:id accepts an update that keeps a start date already before today` | pass |
| C23 | `run req / PASSED DELETE /api/v1/projects/:id deletes the project and its cover image` | pass |
| C24 | `run req / PASSED GET /api/v1/projects returns only the current user's projects` | pass |
| C25 | `run req / PASSED GET /api/v1/projects orders by name ascending ignoring case by default` | pass |
| C26 | `run req / PASSED GET /api/v1/projects orders by start date descending with sort=recent_start` | pass |
| C27 | `run req / PASSED GET /api/v1/projects orders by end date ascending with overdue projects first with sort=neare` | pass |
| C28 | `run req / PASSED GET /api/v1/projects breaks ties by name then id` | pass |
| C29 | `run req / PASSED GET /api/v1/projects rejects an unknown sort value` | pass |
| C30 | `run req / PASSED GET /api/v1/projects returns at most 20 projects per page with the pagination block` | pass |
| C31 | `run req / PASSED GET /api/v1/projects returns the requested page` | pass |
| C32 | `run req / PASSED GET /api/v1/projects returns an empty list beyond the last page` | pass |
| C33 | `run req / PASSED GET /api/v1/projects returns an empty list when the user has no projects` | pass |
| C34 | `run req / PASSED GET /api/v1/projects with search returns projects whose name or client name contains the term` | pass |
| C35 | `run req / PASSED GET /api/v1/projects with search matches ignoring letter case` | pass |
| C36 | `run req / PASSED GET /api/v1/projects with search matches ignoring accents` | pass |
| C37 | `run req / PASSED GET /api/v1/projects with search rejects a search with fewer than 3 characters` | pass |
| C38 | `run req / PASSED GET /api/v1/projects with search returns every project when search is blank` | pass |
| C39 | `run req / PASSED GET /api/v1/projects with search returns the filtered projects in the chosen order` | pass |
| C40 | `run req / PASSED GET /api/v1/projects with search treats % and _ as literal characters` | pass |
| C41 | `run req / PASSED Project favorites POST /api/v1/projects/:project_id/favorite marks the project as favorite` | pass |
| C42 | `run req / PASSED Project favorites DELETE /api/v1/projects/:project_id/favorite unmarks the project as favorit` | pass |
| C43 | `run req / PASSED Project favorites POST /api/v1/projects/:project_id/favorite keeps favorite true when already` | pass |
| C44 | `run req / PASSED Project favorites DELETE /api/v1/projects/:project_id/favorite keeps favorite false when not ` | pass |
| C45 | `run req / PASSED Project favorites changes no field other than favorite` | pass |
| C46 | `run req / PASSED Project endpoints access answers 404 on every project endpoint for a missing or another user'` | pass |
| C48 | `run req / PASSED POST /api/v1/projects treats non-ASCII spaces as word separators and strips them` | pass |
| C47 | `run req / PASSED Project endpoints access answers 401 on every project endpoint without a valid session token` | pass |
| C49 | `run req / PASSED GET /api/v1/projects lists only favorite projects with favorite=true and only the others with` | pass |
| C50 | `run req / PASSED GET /api/v1/projects combines the favorite filter with search and sort` | pass |
| C51 | `run req / PASSED GET /api/v1/projects rejects a favorite value other than true or false` | pass |
| C52 | `run req / PASSED PATCH /api/v1/projects/:id removes the cover image with remove_cover_image=true and keeps the` | pass |
| C53 | `run req / PASSED PATCH /api/v1/projects/:id removes the cover image with remove_cover_image=true sent as JSON` | pass |
| C54 | `run req / PASSED PATCH /api/v1/projects/:id answers 200 when removing the cover image of a project without one` | pass |
| C55 | `run req / PASSED PATCH /api/v1/projects/:id keeps the cover image when remove_cover_image is false or absent` | pass |
| C56 | `run req / PASSED PATCH /api/v1/projects/:id uses the new upload when cover_image and remove_cover_image=true c` | pass |
| C57 | `run req / PASSED POST /api/v1/projects ignores remove_cover_image sent on create` | pass |
| Build | `docker compose exec -T api bin/rubocop` | pass |
| Build | `docker compose exec -T api bundle exec i18n-tasks missing` | pass |
| Build | `docker compose exec -T api bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error` | pass |
| Build | `docker compose exec -T api bin/rspec` | pass |

## Output

`Run req` - exit 0

```
PASSED PATCH /api/v1/projects/:id when authenticated uses the new upload when cover_image and remove_cover_image=true come together
PASSED PATCH /api/v1/projects/:id when authenticated replaces the previous cover image
PASSED PATCH /api/v1/projects/:id when authenticated rejects an end date before the start date and keeps the project unchanged
PASSED PATCH /api/v1/projects/:id when authenticated rejects a changed date before today and keeps the project unchanged
PASSED PATCH /api/v1/projects/:id when authenticated accepts an update that keeps a start date already before today
PASSED PATCH /api/v1/projects/:id when authenticated rejects a project name with fewer than two words
PASSED PATCH /api/v1/projects/:id when authenticated answers 404 for another user's project
PASSED PATCH /api/v1/projects/:id when unauthenticated behaves like an unauthorized API request does not authorize the request
PASSED Project favorites changes no field other than favorite
PASSED Project favorites POST /api/v1/projects/:project_id/favorite marks the project as favorite
PASSED Project favorites POST /api/v1/projects/:project_id/favorite keeps favorite true when already favorited
PASSED Project favorites POST /api/v1/projects/:project_id/favorite when unauthenticated behaves like an unauthorized API request does not authorize the request
PASSED Project favorites DELETE /api/v1/projects/:project_id/favorite unmarks the project as favorite
PASSED Project favorites DELETE /api/v1/projects/:project_id/favorite keeps favorite false when not favorited
PASSED Project favorites DELETE /api/v1/projects/:project_id/favorite when unauthenticated behaves like an unauthorized API request does not authorize the request
```
