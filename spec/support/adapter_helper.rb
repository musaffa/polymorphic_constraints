module Support
  module AdapterHelper
    def execute(sql, name = nil)
      sql_statements << sql
      sql
    end

    def sql_statements
      @sql_statements ||= []
    end

    def strip_non_essential_spaces(string_to_strip)
      string_to_strip.gsub(/\s{2,}|\\n/, " ").strip
    end
  end
end
