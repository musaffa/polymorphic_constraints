module PolymorphicConstraints
  module ConnectionAdapters
    module SchemaStatements
      def self.included(base)
        base::AbstractAdapter.class_eval do
          include PolymorphicConstraints::ConnectionAdapters::AbstractAdapter
        end
      end
    end

    module AbstractAdapter
      def supports_polymorphic_constraints?
        false
      end

      def add_polymorphic_constraints(relation, associated_model, options = {})
      end

      def remove_polymorphic_constraints(relation)
      end
    end
  end
end
