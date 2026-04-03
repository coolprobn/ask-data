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

    def self.safe_execution_role_sql
      r = execution_role
      return nil if r.blank?
      raise ArgumentError, "invalid execution_role" unless r.match?(/\A[a-z_][a-z0-9_]*\z/i)

      ActiveRecord::Base.connection.quote_column_name(r)
    end
  end
end
