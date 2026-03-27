# frozen_string_literal: true

module NlQuery
  # Minimal schema text for the LLM until Epic 2’s full snapshot builder.
  class SchemaSnapshot
    def self.for_llm
      conn = ActiveRecord::Base.connection
      lines = []
      Exposure.allowed_tables.each do |table|
        result = conn.exec_query(sanitize_columns_sql(conn, table))
        lines << "Table #{table}:"
        if result.rows.empty?
          lines << "  (no columns found)"
        else
          result.each do |row|
            lines << "  #{row['column_name']} (#{row['data_type']})"
          end
        end
        lines << ""
      end
      lines.join("\n").strip
    end

    def self.sanitize_columns_sql(conn, table)
      raise ArgumentError, "invalid table" unless Exposure.table_allowed?(table)

      ActiveRecord::Base.sanitize_sql_array([
        <<~SQL.squish,
          SELECT column_name, data_type
          FROM information_schema.columns
          WHERE table_schema = 'public' AND table_name = ?
          ORDER BY ordinal_position
        SQL
        table
      ])
    end
    private_class_method :sanitize_columns_sql
  end
end
