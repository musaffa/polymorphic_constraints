module PolymorphicConstraints
  module Utils
    module SqlString
      def strip_non_essential_spaces(string_to_strip)
        string_to_strip.gsub(/\s{2,}|\\n/, " ").strip
      end
    end
  end
end
