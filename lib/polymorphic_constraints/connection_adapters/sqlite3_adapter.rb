require 'active_support/inflector'
require_relative '../utils/sql_string'
require_relative '../utils/model_finder'

module PolymorphicConstraints
  module ConnectionAdapters
    module SQLite3Adapter
      include PolymorphicConstraints::Utils::SqlString
      include PolymorphicConstraints::Utils::ModelFinder

      def supports_polymorphic_constraints?
        true
      end

      def add_polymorphic_constraints(relation, associated_table, options = {})
        search_strategy = options.fetch(:search_strategy, :active_record_descendants)
        polymorphic_models = options.fetch(:polymorphic_models) { get_polymorphic_models(relation, search_strategy) }
        statements = []

        statements << drop_trigger(relation, 'insert')
        statements << generate_create_constraints(relation, associated_table, polymorphic_models)

        statements << drop_trigger(relation, 'update')
        statements << generate_update_constraints(relation, associated_table, polymorphic_models)

        polymorphic_models.each do |polymorphic_model|
          statements << drop_delete_trigger(relation, polymorphic_model)
          statements << generate_delete_constraints(relation, associated_table, polymorphic_model)
        end

        statements.each { |statement| execute statement }
      end

      def remove_polymorphic_constraints(relation, options = {})
        search_strategy = options.fetch(:search_strategy, :active_record_descendants)
        polymorphic_models = options.fetch(:polymorphic_models) { get_polymorphic_models(relation, search_strategy) }
        statements = []

        statements << drop_trigger(relation, 'insert')
        statements << drop_trigger(relation, 'update')

        polymorphic_models.each do |polymorphic_model|
          statements << drop_delete_trigger(relation, polymorphic_model)
        end

        statements.each { |statement| execute statement }
      end

      private

      def drop_trigger(relation, action)
        strip_non_essential_spaces "DROP TRIGGER IF EXISTS check_#{relation}_#{action}_integrity;"
      end

      def drop_delete_trigger(relation, polymorphic_model)
        table_name = polymorphic_model.to_s.classify.constantize.table_name
        strip_non_essential_spaces "DROP TRIGGER IF EXISTS check_#{relation}_#{table_name}_delete_integrity;"
      end

      def generate_create_constraints(relation, associated_table, polymorphic_models)
        associated_table = associated_table.to_s

        sql = %{
          CREATE TRIGGER check_#{relation}_insert_integrity
            BEFORE INSERT ON #{associated_table}
        }

        sql << common_upsert_sql(relation, polymorphic_models)

        strip_non_essential_spaces(sql)
      end

      def generate_update_constraints(relation, associated_table, polymorphic_models)
        associated_table = associated_table.to_s
        polymorphic_models = polymorphic_models.map(&:to_s)

        sql = %{
          CREATE TRIGGER check_#{relation}_update_integrity
            BEFORE UPDATE ON #{associated_table}
        }

        sql << common_upsert_sql(relation, polymorphic_models)

        strip_non_essential_spaces(sql)
      end

      def generate_delete_constraints(relation, associated_table, polymorphic_model)
        associated_table = associated_table.to_s
        polymorphic_model = polymorphic_model.to_s
        
        sql = %{
          CREATE TRIGGER check_#{relation}_#{polymorphic_model.classify.constantize.table_name}_delete_integrity
            BEFORE DELETE ON #{polymorphic_model.classify.constantize.table_name}
            BEGIN
              SELECT CASE
                WHEN EXISTS (SELECT id FROM #{associated_table}
                             WHERE #{relation}_type = '#{polymorphic_model.classify}'
                             AND #{relation}_id = OLD.id) THEN
                  RAISE(ABORT, 'There are records in the #{associated_table} table that refer to the
                                table #{polymorphic_model.classify.constantize.table_name}.
                                You must delete those records of table #{associated_table} first.')
              END;
            END;
        }

        strip_non_essential_spaces(sql)
      end

      def common_upsert_sql(relation, polymorphic_models)
        polymorphic_models = polymorphic_models.map(&:to_s)

        sql = %{
          BEGIN
            SELECT CASE
        }

        sql << 'WHEN ('

        polymorphic_models.each do |polymorphic_model|
          sql << %{NEW.#{relation}_type != '#{polymorphic_model.classify}' }
          sql << 'AND ' unless polymorphic_model == polymorphic_models.last
        end

        sql << %{) THEN RAISE(ABORT, 'There is no model by that name.') }

        polymorphic_models.each do |polymorphic_model|
          sql << %{
            WHEN ((NEW.#{relation}_type = '#{polymorphic_model.classify}') AND
                  NOT EXISTS (SELECT id FROM #{polymorphic_model.classify.constantize.table_name}
                              WHERE id = NEW.#{relation}_id)) THEN
              RAISE(ABORT, 'There is no #{polymorphic_model.classify} with that id.')
          }
        end

        sql << "END; END;"
      end
    end
  end
end

PolymorphicConstraints::Adapter.safe_include :SQLite3Adapter, PolymorphicConstraints::ConnectionAdapters::SQLite3Adapter
