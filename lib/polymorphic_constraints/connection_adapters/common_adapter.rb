require 'active_support/inflector'

module PolymorphicConstraints
  module ConnectionAdapters
    module CommonAdapter
      include BaseAdapter

      private

      def drop_constraints(relation)
        polymorphic_models = get_polymorphic_models(relation)

        statements = []
        statements << drop_trigger(relation, 'insert')
        statements << drop_trigger(relation, 'update')

        polymorphic_models.each do |polymorphic_model|
          statements << drop_delete_trigger(relation, polymorphic_model)
        end

        statements
      end

      def drop_trigger(relation, action)
        sql = <<-SQL
          DROP TRIGGER IF EXISTS check_#{relation}_#{action}_integrity;
        SQL

        strip_non_essential_spaces(sql)
      end

      def drop_delete_trigger(relation, polymorphic_model)
        table_name = polymorphic_model.to_s.classify.constantize.table_name

        sql = <<-SQL
          DROP TRIGGER IF EXISTS check_#{relation}_#{table_name}_delete_integrity;
        SQL

        strip_non_essential_spaces(sql)
      end

      def generate_upsert_constraints(relation, associated_table, polymorphic_models)
        statements = []
        statements << generate_insert_constraints(relation, associated_table, polymorphic_models)
        statements << generate_update_constraints(relation, associated_table, polymorphic_models)
        statements
      end

      def generate_insert_constraints(relation, associated_table, polymorphic_models)
        associated_table = associated_table.to_s

        sql = <<-SQL
          CREATE TRIGGER check_#{relation}_insert_integrity
            BEFORE INSERT ON #{associated_table}
        SQL

        sql << common_upsert_sql(relation, polymorphic_models)

        strip_non_essential_spaces(sql)
      end

      def generate_update_constraints(relation, associated_table, polymorphic_models)
        associated_table = associated_table.to_s
        polymorphic_models = polymorphic_models.map(&:to_s)

        sql = <<-SQL
          CREATE TRIGGER check_#{relation}_update_integrity
            BEFORE UPDATE ON #{associated_table}
        SQL

        sql << common_upsert_sql(relation, polymorphic_models)

        strip_non_essential_spaces(sql)
      end

      def generate_delete_constraints(relation, associated_table, polymorphic_models)
        statements = []

        polymorphic_models.each do |polymorphic_model|
          statements << delete_statement(relation, associated_table, polymorphic_model)
        end

        statements
      end
    end
  end
end
