module PolymorphicConstraints
  module ConnectionAdapters
    module BaseAdapter
      include PolymorphicConstraints::Utils::SqlString
      include PolymorphicConstraints::Utils::PolymorphicModelFinder

      def supports_polymorphic_constraints?
        true
      end

      def add_polymorphic_constraints(relation, associated_table, options = {})
        polymorphic_models = options.fetch(:polymorphic_models) { get_polymorphic_models(relation) }

        statements = []
        statements << drop_constraints(relation)
        statements << generate_upsert_constraints(relation, associated_table, polymorphic_models)
        statements << generate_delete_constraints(relation, associated_table, polymorphic_models)

        statements.flatten.each { |statement| execute statement }
      end

      def remove_polymorphic_constraints(relation)
        statements = []
        statements << drop_constraints(relation)
        statements.flatten.each { |statement| execute statement }
      end

      alias_method :update_polymorphic_constraints, :add_polymorphic_constraints
    end
  end
end
