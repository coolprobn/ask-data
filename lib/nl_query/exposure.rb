# frozen_string_literal: true

module NlQuery
  # Single source of truth for which tables/columns may appear in LLM schema text and result rows.
  # Loaded from config/nl_query.yml (see README).
  module Exposure
    class << self
      def config
        @config ||= Rails.application.config_for(:nl_query).deep_symbolize_keys
      end

      def reload!
        @config = nil
        @forbidden_regexes = nil
        @explicit_forbidden = nil
      end

      def allowed_tables
        Array(config[:allowed_tables]).map(&:to_s)
      end

      def table_allowed?(table_name)
        allowed_tables.include?(table_name.to_s)
      end

      def column_exposed?(table_name, column_name)
        return false unless table_allowed?(table_name)

        col = column_name.to_s
        return false if explicit_forbidden_list(table_name).include?(col)
        return false if forbidden_regexes.any? { |re| col.match?(re) }

        true
      end

      # Column names safe to list in LLM-facing schema snapshot text.
      def filter_columns_for_llm(table_name, column_names)
        column_names.map(&:to_s).select { |c| column_exposed?(table_name, c) }
      end

      # Builds multi-line schema text for one table; omits forbidden columns entirely.
      def llm_schema_lines_for_table(table_name, columns_with_types)
        columns_with_types.filter_map do |entry|
          name = (entry[:name] || entry["name"]).to_s
          next unless column_exposed?(table_name, name)

          type = (entry[:type] || entry["type"]).to_s
          "  #{name} (#{type})"
        end
      end

      # Strips forbidden keys from a result row (string or symbol keys).
      def redact_result_row(table_name, row)
        return {} unless table_allowed?(table_name)
        return row if row.blank?

        out = {}
        row.each do |key, value|
          k = key.to_s
          out[key] = value if column_exposed?(table_name, k)
        end
        out
      end

      private

      def explicit_forbidden_list(table_name)
        key = table_name.to_s
        h = explicit_forbidden
        list = h[key] || h[key.to_sym]
        Array(list).map(&:to_s)
      end

      def explicit_forbidden
        @explicit_forbidden ||= begin
          raw = config[:explicit_forbidden_columns]
          raw.is_a?(Hash) ? raw.stringify_keys : {}
        end
      end

      def forbidden_regexes
        @forbidden_regexes ||= Array(config[:forbidden_column_patterns]).map do |src|
          Regexp.new(src.to_s)
        end
      end
    end
  end
end
