# frozen_string_literal: true

require "set"

module NlQuery
  # AST walk: allowlisted tables/columns only; deny SELECT * / tbl.* (Ticket 3.2).
  class SqlSelectAllowlist
    # Returns nil if OK, or a failure reason symbol for SqlGuard::Validation.
    def self.validate(select_stmt, cte_names: Set.new)
      walk_select_stmt(select_stmt, cte_names)
    end

    def self.walk_select_stmt(stmt, cte_names)
      local_cte = cte_names.dup

      if stmt.with_clause
        names = stmt.with_clause.ctes.map { |n| n.common_table_expr.ctename }
        local_cte.merge(names)

        stmt.with_clause.ctes.each do |n|
          cte = n.common_table_expr
          err = walk_select_stmt(cte.ctequery.select_stmt, local_cte)
          return err if err
        end
      end

      alias_map = {}
      stmt.from_clause.each do |n|
        err = walk_from_item(n, alias_map, local_cte)
        return err if err
      end

      stmt.target_list&.each do |n|
        err = walk_expr(n.res_target.val, alias_map, local_cte)
        return err if err
      end

      err = walk_expr(stmt.where_clause, alias_map, local_cte)
      return err if err

      stmt.group_clause&.each do |n|
        err = walk_expr(n, alias_map, local_cte)
        return err if err
      end

      err = walk_expr(stmt.having_clause, alias_map, local_cte)
      return err if err

      stmt.sort_clause&.each do |n|
        sb = n.sort_by
        err = walk_expr(sb.node, alias_map, local_cte) if sb
        return err if err
      end

      nil
    end
    private_class_method :walk_select_stmt

    def self.walk_from_item(node, alias_map, cte_names)
      return unless node

      if node.range_var
        rv = node.range_var
        return :disallowed_schema unless schema_public_or_unqualified?(rv)

        rel = rv.relname
        return :disallowed_table unless table_ref_allowed?(rel, cte_names)

        alias_name = rv.alias&.aliasname.presence || rel
        alias_map[alias_name] = cte_names.include?(rel) ? :cte : rel
        nil
      elsif node.join_expr
        j = node.join_expr
        err = walk_from_item(j.larg, alias_map, cte_names)
        return err if err
        err = walk_from_item(j.rarg, alias_map, cte_names)
        return err if err
        err = walk_expr(j.quals, alias_map, cte_names)
        return err if err
        nil
      elsif node.range_subselect
        rs = node.range_subselect
        err = walk_select_stmt(rs.subquery.select_stmt, cte_names)
        return err if err
        alias_map[rs.alias.aliasname] = :subquery
        nil
      end
    end
    private_class_method :walk_from_item

    def self.schema_public_or_unqualified?(rv)
      s = rv.schemaname.to_s
      s.empty? || s == "public"
    end
    private_class_method :schema_public_or_unqualified?

    def self.table_ref_allowed?(rel, cte_names)
      cte_names.include?(rel) || Exposure.table_allowed?(rel)
    end
    private_class_method :table_ref_allowed?

    def self.walk_expr(node, alias_map, cte_names)
      return unless node

      if node.column_ref
        return check_column_ref(node.column_ref, alias_map, cte_names)
      elsif node.bool_expr
        node.bool_expr.args.each do |a|
          err = walk_expr(a, alias_map, cte_names)
          return err if err
        end
      elsif node.a_expr
        ae = node.a_expr
        err = walk_expr(ae.lexpr, alias_map, cte_names)
        return err if err
        return walk_expr(ae.rexpr, alias_map, cte_names)
      elsif node.sub_link
        return walk_select_stmt(node.sub_link.subselect.select_stmt, cte_names)
      elsif node.func_call
        node.func_call.args.each do |a|
          err = walk_expr(a, alias_map, cte_names)
          return err if err
        end
      elsif node.type_cast
        return walk_expr(node.type_cast.arg, alias_map, cte_names)
      elsif node.null_test
        return walk_expr(node.null_test.arg, alias_map, cte_names)
      elsif node.list
        node.list.items.each do |x|
          err = walk_expr(x, alias_map, cte_names)
          return err if err
        end
      elsif node.coalesce_expr
        node.coalesce_expr.args.each do |a|
          err = walk_expr(a, alias_map, cte_names)
          return err if err
        end
      elsif node.case_expr
        ce = node.case_expr
        ce.args.each do |a|
          err = walk_expr(a, alias_map, cte_names)
          return err if err
        end
        err = walk_expr(ce.defresult, alias_map, cte_names) if ce.defresult
        return err if err
      elsif node.row_expr
        node.row_expr.args.each do |a|
          err = walk_expr(a, alias_map, cte_names)
          return err if err
        end
      elsif node.scalar_array_op_expr
        return walk_expr(node.scalar_array_op_expr.xpr, alias_map, cte_names)
      elsif node.a_const
        nil
      end

      nil
    end
    private_class_method :walk_expr

    def self.check_column_ref(cr, alias_map, cte_names)
      return :select_star if cr.fields.any? { |f| f.a_star }

      names = cr.fields.filter_map { |f| f.string&.sval }
      return nil if names.empty?

      if names.length == 1
        col = names.first
        bases = alias_map.values.select { |v| v.is_a?(String) }.uniq
        return nil if bases.empty?

        return :disallowed_column unless bases.any? { |t| Exposure.column_exposed?(t, col) }
      else
        qualifier = names[0]
        rest = names[1..]
        return :select_star if rest.empty?

        return :select_star if cr.fields[1]&.a_star

        col = rest[0]
        base = alias_map[qualifier]
        base = qualifier if base.nil? && Exposure.table_allowed?(qualifier)

        if base == :subquery || base == :cte || (base.nil? && cte_names.include?(qualifier))
          return nil
        end

        return :disallowed_table unless base.is_a?(String) && Exposure.table_allowed?(base)

        return :disallowed_column unless Exposure.column_exposed?(base, col)
      end

      nil
    end
    private_class_method :check_column_ref
  end
end
