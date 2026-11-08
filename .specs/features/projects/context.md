# Projects Context

**Gathered:** 2026-11-05
**Spec:** `.specs/features/projects/spec.md`
**Status:** Ready for spec

---

## Feature Boundary

Authenticated CRUD of projects (name, client, start date, end date, cover image, favorite), a separate favorite/unfavorite endpoint, three sort orders and a search by project or client name with a 3-character minimum.

---

## Implementation Decisions

### Ownership

- user: "Do usuário criador" - each project belongs to the user who created it; users only see and change their own.

### Client

- user: "Texto no projeto" - client is a string column on the project, no Client entity.

### Cover image

- user: "Upload via Active Storage, aceitar apenas jpg e png" - multipart upload through Active Storage; only JPEG and PNG accepted.

### Short search

- user: "Retorna 422 com erro" - a search term shorter than 3 characters returns 422.

### Required fields and dates

- user: "Nome, cliente e datas" - name, client, start date and end date required; end date >= start date; cover optional; favorite starts false and is not accepted on create/update.

### Nearest-deadline sort

- user: "Data de fim crescente" - end_date ascending for all projects; overdue ones (end date before today) come last (user: "deixar para o final os projetos com prazo que já passou").
- user: recent_start shows started projects first (start date up to today, newest first), then not-started ones (start date after today), then overdue ones.

### Favorite endpoint

- user: "POST/DELETE /favorite" - POST /api/v1/projects/:id/favorite marks, DELETE unmarks; idempotent; responds with the project.

### Search comparison

- user: "Sem maiúsc. e sem acento" - partial match, case- and accent-insensitive (Postgres unaccent).

### Name and date rules (adjustment)

- user: "ajuste para nome do projeto ter pelo menos duas palavras"
- user: "America/Sao_Paulo" - today is computed in Brasília time; the app's `config.time_zone` becomes `America/Sao_Paulo`.
- user (2026-11-08): "remova a validação não pode ser anterior a hoje" - start and end dates may be earlier than today.

### Declined / Undiscussed Gray Areas → Assumptions

Logged in spec.md Assumptions (cover size limit, pagination, sort param names, deletion, name length).

---

## Specific References

No specific requirements - open to standard approaches.

---

## Deferred Ideas

None - discussion stayed within feature scope.
