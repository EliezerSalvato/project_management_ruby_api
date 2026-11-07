class Project < ApplicationRecord
  belongs_to :user

  has_one_attached :cover_image

  scope :search, ->(term) do
    pattern = "%#{sanitize_sql_like(term)}%"

    where("unaccent(projects.name) ILIKE unaccent(:pattern) OR unaccent(projects.client_name) ILIKE unaccent(:pattern)", pattern:)
  end

  scope :sorted_by, ->(key, today:) do
    order(Arel.sql(sanitize_sql([ Project::Sort::KEYS.fetch(key).map { "#{it} ASC" }.join(", "), { today: } ])))
  end

  # Rows that come after the cursor project, comparing the same keyset used by sorted_by.
  scope :after_cursor, ->(cursor_id, key, today:) do
    where(Project::Sort::AFTER_CURSOR.fetch(key), cursor_id:, today:)
  end
end
