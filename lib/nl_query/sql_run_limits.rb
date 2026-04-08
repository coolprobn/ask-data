# frozen_string_literal: true

require "pg_query"

module NlQuery
  # Epic 3.3: clamp or append a numeric LIMIT on the outer SelectStmt (pg_query + deparse).
  class SqlRunLimits
    # Returns [rewritten_sql, nil] or [nil, reason_symbol].
    def self.ensure_max_rows(sql, max_rows: RunLimits.max_result_rows)
      return [ sql.to_s, nil ] if max_rows <= 0

      tree = PgQuery.parse(sql).tree
      stmt = tree.stmts[0].stmt.select_stmt
      reason = apply_to_select_stmt!(stmt, max_rows)
      return [ nil, reason ] if reason

      [ PgQuery.deparse(tree), nil ]
    rescue PgQuery::ParseError => e
      Rails.logger.warn { "[SqlRunLimits] parse error: #{e.message}" }
      [ nil, :parse_error ]
    end

    def self.apply_to_select_stmt!(stmt, max_rows)
      case stmt.limit_option
      when :LIMIT_OPTION_DEFAULT
        stmt.limit_option = :LIMIT_OPTION_COUNT
        stmt.limit_count = integer_const_node(max_rows)
        nil
      when :LIMIT_OPTION_COUNT
        if limit_all?(stmt.limit_count)
          stmt.limit_count = integer_const_node(max_rows)
          return nil
        end

        val = integer_limit_value(stmt.limit_count)
        return :dynamic_limit if val.nil?

        if val > max_rows
          stmt.limit_count = integer_const_node(max_rows)
        end
        nil
      else
        :unsupported_limit
      end
    end
    private_class_method :apply_to_select_stmt!

    def self.limit_all?(limit_node)
      limit_node&.a_const&.isnull
    end
    private_class_method :limit_all?

    def self.integer_limit_value(node)
      return nil unless node
      return nil if node.column_ref || node.param_ref || node.sub_link || node.func_call || node.a_expr

      c = node.a_const
      return nil unless c
      return nil if c.isnull

      c.ival&.ival
    end
    private_class_method :integer_limit_value

    def self.integer_const_node(n)
      PgQuery::Node.new(
        a_const: PgQuery::A_Const.new(
          ival: PgQuery::Integer.new(ival: n.to_i),
          isnull: false
        )
      )
    end
    private_class_method :integer_const_node
  end
end
