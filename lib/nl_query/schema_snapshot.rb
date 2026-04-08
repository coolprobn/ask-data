# frozen_string_literal: true

module NlQuery
  # LLM-facing schema text: allowlisted tables, redacted columns, primary keys, and foreign-key hints.
  class SchemaSnapshot
    def self.for_llm
      conn = ActiveRecord::Base.connection
      lines = []
      Exposure.allowed_tables.each do |table|
        lines << "Table #{table}:"

        cols = columns_with_types(conn, table)
        col_lines = Exposure.llm_schema_lines_for_table(table, cols)
        if col_lines.empty?
          lines << "  (no exposed columns)"
        else
          col_lines.each { |l| lines << l }
        end

        pk_line = primary_key_line(conn, table)
        lines << pk_line if pk_line

        fk_lines = foreign_key_lines(conn, table)
        lines.concat(fk_lines) if fk_lines.any?

        lines << ""
      end
      lines.join("\n").strip
    end

    def self.columns_with_types(conn, table)
      raise ArgumentError, "invalid table" unless Exposure.table_allowed?(table)

      result = conn.exec_query(sanitize_columns_sql(conn, table))
      result.to_a.filter_map do |row|
        name = row["column_name"]
        next unless Exposure.column_exposed?(table, name)

        { "name" => name, "type" => row["data_type"] }
      end
    end
    private_class_method :columns_with_types

    def self.primary_key_line(conn, table)
      return unless Exposure.table_allowed?(table)

      pk = conn.primary_key(table)
      parts = Array(pk).compact.map(&:to_s).select { |c| Exposure.column_exposed?(table, c) }
      return if parts.empty?

      "  Primary key: #{parts.join(', ')}"
    end
    private_class_method :primary_key_line

    def self.foreign_key_lines(conn, table)
      return [] unless Exposure.table_allowed?(table)

      hints = []
      conn.foreign_keys(table).each do |fk|
        next unless Exposure.table_allowed?(fk.to_table)

        fk_cols = Array(fk.column)
        pk_cols = Array(fk.primary_key)
        next if fk_cols.empty? || fk_cols.size != pk_cols.size

        fk_cols.each_with_index do |from_col, i|
          to_col = pk_cols[i]
          next unless Exposure.column_exposed?(table, from_col)
          next unless Exposure.column_exposed?(fk.to_table, to_col)

          hints << "    #{from_col} → #{fk.to_table}.#{to_col}"
        end
      end
      return [] if hints.empty?

      [ "  Foreign keys:" ] + hints
    end
    private_class_method :foreign_key_lines

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
