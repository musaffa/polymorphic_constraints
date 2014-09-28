module PolymorphicConstraints
  module ConnectionAdapters
    module SchemaDefinitions
      def self.included(base)
        base::Table.class_eval do
          include PolymorphicConstraints::ConnectionAdapters::Table
        end
      end
    end
  end
end