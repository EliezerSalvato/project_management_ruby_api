# String#strip and #split only know ASCII whitespace; names and searches typed or pasted
# by users may carry non-breaking or other Unicode spaces.
module Project::Text
  WHITESPACE = /[[:space:]]+/

  def self.strip(value)
    value.to_s.gsub(/\A[[:space:]]+|[[:space:]]+\z/, "")
  end
end
