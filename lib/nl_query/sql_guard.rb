# frozen_string_literal: true

require "pg_query"

module NlQuery
  # SELECT-only gate using PostgreSQL's parser (Ticket 3.1). Epic 3.2 adds identifier allowlists.
  class SqlGuard
    Validation = Struct.new(:success, :reason, keyword_init: true)

    def self.validate(sql)
      s = sql.to_s.strip
      return Validation.new(success: false, reason: :empty) if s.blank?

      result = begin
        PgQuery.parse(s)
      rescue PgQuery::ParseError => e
        Rails.logger.info { "[SqlGuard] parse error: #{e.message}" }
        return Validation.new(success: false, reason: :parse_error)
      end

      tree = result.tree
      stmts = tree.stmts
      return Validation.new(success: false, reason: :empty) if stmts.empty?

      if stmts.size > 1
        return Validation.new(success: false, reason: :multi_statement)
      end

      node = stmts.first.stmt
      unless node&.select_stmt
        return Validation.new(success: false, reason: :not_select)
      end

      if (allowlist_reason = SqlSelectAllowlist.validate(node.select_stmt))
        return Validation.new(success: false, reason: allowlist_reason)
      end

      Validation.new(success: true, reason: nil)
    end
  end
end
