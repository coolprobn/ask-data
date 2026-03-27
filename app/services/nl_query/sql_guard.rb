# frozen_string_literal: true

module NlQuery
  # Minimal read-only gate (Epic 3 adds full parsing + allowlist walks).
  class SqlGuard
    FORBIDDEN_KEYWORDS = /
      \b(INSERT|UPDATE|DELETE|DROP|ALTER|TRUNCATE|CREATE|GRANT|REVOKE|COPY|EXECUTE)\b
    /ix

    Validation = Struct.new(:success, :reason, keyword_init: true)

    def self.validate(sql)
      s = sql.to_s.strip
      return Validation.new(success: false, reason: :empty) if s.blank?

      return Validation.new(success: false, reason: :multi_statement) if multi_statement?(s)

      return Validation.new(success: false, reason: :forbidden_keyword) if s.match?(FORBIDDEN_KEYWORDS)

      return Validation.new(success: false, reason: :not_select) unless s.match?(/\A\s*(WITH|SELECT)\b/mi)

      Validation.new(success: true, reason: nil)
    end

    def self.multi_statement?(sql)
      core = sql.sub(/;\s*\z/, "")
      core.include?(";")
    end
    private_class_method :multi_statement?
  end
end
