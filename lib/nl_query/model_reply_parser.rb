# frozen_string_literal: true

module NlQuery
  # Extracts SQL and optional rationale from a model reply (including fenced ```sql blocks).
  module ModelReplyParser
    module_function

    FENCED_SQL = /```sql\s*\n([\s\S]*?)```/mi
    FENCED_GENERIC = /```\s*\n(\s*SELECT[\s\S]*?)```/mi

    def parse(text)
      raw = text.to_s
      sql = extract_sql(raw)
      rationale = extract_rationale(raw)
      TextToSqlResult.new(sql:, rationale:, raw: raw)
    end

    def extract_sql(text)
      if (m = text.match(FENCED_SQL))
        return normalize_sql(m[1])
      end
      if (m = text.match(FENCED_GENERIC))
        return normalize_sql(m[1])
      end

      fallback_select_sql(text)
    end

    def extract_rationale(text)
      stripped = text.dup
      stripped.sub!(FENCED_SQL, "")
      stripped.sub!(FENCED_GENERIC, "")
      stripped.strip.presence
    end

    def normalize_sql(fragment)
      s = fragment.to_s.strip
      s = s.sub(/\A\s*;\s*\z/, "")
      s.presence
    end

    def fallback_select_sql(text)
      text.each_line.map(&:strip).find { |line| line.match?(/\A\s*(WITH|SELECT)\b/i) }
    end
  end
end
