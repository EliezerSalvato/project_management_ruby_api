module Project::Sort
  DEFAULT = "name".freeze

  STAGES = { started: 0, upcoming: 1, overdue: 2 }.freeze

  TODAY = "CAST(:today AS date)".freeze

  # Overdue projects (deadline before today) go last in the date-based orders.
  OVERDUE = "(projects.end_date < #{TODAY})".freeze

  # Started, upcoming, then overdue.
  STAGE = "CASE WHEN projects.end_date < #{TODAY} THEN #{STAGES[:overdue]} " \
          "WHEN projects.start_date > #{TODAY} THEN #{STAGES[:upcoming]} " \
          "ELSE #{STAGES[:started]} END".freeze

  # Days until an upcoming start, days since any other start.
  START_DISTANCE = "ABS(projects.start_date - #{TODAY})".freeze

  NAME = "LOWER(projects.name)".freeze

  # Ordered keyset expressions, all ascending. Drives both ORDER BY and the cursor comparison.
  KEYS = {
    "name" => [ NAME, "projects.id" ],
    "recent_start" => [ STAGE, START_DISTANCE, NAME, "projects.id" ],
    "nearest_deadline" => [ OVERDUE, "projects.end_date", NAME, "projects.id" ]
  }.freeze

  # Rows after the cursor project, comparing the same keyset. Built once from KEYS so no SQL is assembled per request.
  AFTER_CURSOR = KEYS.transform_values do |expressions|
    keyset = expressions.join(", ")

    "(#{keyset}) > (SELECT #{keyset} FROM projects WHERE projects.id = :cursor_id)".freeze
  end.freeze
end
