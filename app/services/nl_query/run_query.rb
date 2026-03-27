# frozen_string_literal: true

module NlQuery
  # Executes SqlGuard-approved SELECTs only (Epic 3 adds timeouts + row caps).
  class RunQuery
    class ExecutionError < Error; end

    def self.perform(sql)
      validation = SqlGuard.validate(sql)
      raise ExecutionError, "invalid_sql" unless validation.success

      result = ActiveRecord::Base.connection.exec_query(sql)
      [ result.columns, result.to_a ]
    rescue ActiveRecord::StatementInvalid, PG::Error => e
      Rails.logger.warn { "[RunQuery] #{e.class}: #{e.message}" }
      raise ExecutionError, e.message
    end
  end
end
