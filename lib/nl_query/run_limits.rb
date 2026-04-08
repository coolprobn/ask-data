# frozen_string_literal: true

module NlQuery
  # Epic 3.3–3.4: timeouts, row caps, optional execution role (config/nl_query.yml → `run_limits`).
  module RunLimits
    def self.raw
      Exposure.config[:run_limits].is_a?(Hash) ? Exposure.config[:run_limits] : {}
    end

    def self.statement_timeout_ms
      v = raw[:statement_timeout_ms]
      v.nil? ? 15_000 : v.to_i
    end

    def self.max_result_rows
      v = raw[:max_result_rows]
      v.nil? ? 500 : v.to_i
    end

    def self.execution_role
      raw[:execution_role].to_s.presence
    end

    # Returns the configured role name after allowlist validation, or nil if unset.
    # (Quoted identifier for SQL is applied at the call site so static analysis sees quote_column_name.)
    def self.validated_execution_role
      r = execution_role
      return nil if r.blank?
      raise ArgumentError, "invalid execution_role" unless r.match?(/\A[a-z_][a-z0-9_]*\z/i)

      r
    end
  end
end
