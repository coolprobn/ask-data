# frozen_string_literal: true

module NlQuery
  # Epic 3.4: single entry point for executing NL-approved SELECTs (3.1–3.3 applied first).
  class RunQuery
    class ExecutionError < Error; end

    def self.perform(sql)
      validation = SqlGuard.validate(sql)
      raise ExecutionError, "invalid_sql" unless validation.success

      limited_sql, lim_err = SqlRunLimits.ensure_max_rows(sql)
      raise ExecutionError, lim_err.to_s if lim_err

      v2 = SqlGuard.validate(limited_sql)
      raise ExecutionError, "invalid_after_limit" unless v2.success

      run_in_guarded_transaction(limited_sql)
    end

    def self.run_in_guarded_transaction(limited_sql)
      conn = ActiveRecord::Base.connection
      ms = RunLimits.statement_timeout_ms
      result = nil

      conn.transaction do
        begin
          conn.execute("SET TRANSACTION READ ONLY")
        rescue ActiveRecord::StatementInvalid
          Rails.logger.info { "[RunQuery] SET TRANSACTION READ ONLY skipped (nested txn or DB policy)." }
        end

        conn.execute("SET LOCAL statement_timeout = #{ms.to_i}")

        r = RunLimits.validated_execution_role
        if r
          conn.execute("SET LOCAL ROLE #{ActiveRecord::Base.connection.quote_column_name(r)}")
        end

        result = conn.exec_query(limited_sql)
      end

      [ result.columns, result.to_a ]
    rescue ActiveRecord::StatementInvalid, PG::Error => e
      Rails.logger.warn { "[RunQuery] #{e.class}: #{e.message}" }
      raise ExecutionError, e.message
    rescue ArgumentError => e
      Rails.logger.warn { "[RunQuery] #{e.class}: #{e.message}" }
      raise ExecutionError, "configuration_error"
    end
    private_class_method :run_in_guarded_transaction
  end
end
