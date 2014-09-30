require 'active_support/inflector'
require_relative '../utils/sql_string'

module PolymorphicConstraints
  module ConnectionAdapters
    module SQLite3Adapter
      include PolymorphicConstraints::Utils::SqlString

      def supports_polymorphic_constraints?
        true
      end

      def add_polymorphic_constraints(relation, associated_table, options = {})
        polymorphic_models = options.fetch(:polymorphic_models) { get_polymorphic_models(relation) }
        statements = []

        statements << drop_trigger(relation, 'create')
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
        polymorphic_models = options.fetch(:polymorphic_models) { get_polymorphic_models(relation) }
        statements = []

        statements << drop_trigger(relation, 'create')
        statements << drop_trigger(relation, 'update')

        polymorphic_models.each do |polymorphic_model|
          statements << drop_delete_trigger(relation, polymorphic_model)
        end

        statements.each { |statement| execute statement }
      end

      private

      def get_polymorphic_models(relation)
        Rails.application.eager_load!
        ActiveRecord::Base.descendants.select do |klass|
          associations = klass.reflect_on_all_associations
          associations.map{ |r| r.options[:as] }.include?(relation.to_sym)
        end
      end

      def drop_trigger(relation, action)
        strip_non_essential_spaces "DROP TRIGGER IF EXISTS check_#{relation}_#{action}_integrity;"
      end

      def drop_delete_trigger(relation, polymorphic_model)
        table_name = polymorphic_model.to_s.classify.constantize.table_name
        strip_non_essential_spaces "DROP TRIGGER IF EXISTS check_#{relation}_#{table_name}_delete_integrity;"
      end

      def generate_create_constraints(relation, associated_table, polymorphic_models)
        associated_table = associated_table.to_s
        polymorphic_models = polymorphic_models.map(&:to_s)

        sql = %{

          CREATE TRIGGER check_#{relation}_create_integrity
            BEFORE INSERT ON #{associated_table}
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
            WHEN ((NEW.#{relation}_type = '#{polymorphic_model.classify}') AND (SELECT id
              FROM #{polymorphic_model.classify.constantize.table_name}
              WHERE id = NEW.#{relation}_id) ISNULL)
              THEN RAISE(ABORT, 'There is no #{polymorphic_model.classify} with that id.')
          }
        end

        sql << "END; END;"

        strip_non_essential_spaces(sql)
      end

      def generate_update_constraints(relation, associated_table, polymorphic_models)
        associated_table = associated_table.to_s
        polymorphic_models = polymorphic_models.map(&:to_s)

        sql = %{

          CREATE TRIGGER check_#{relation}_update_integrity
            BEFORE UPDATE ON #{associated_table.classify.constantize.table_name}
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
            WHEN ((NEW.#{relation}_type = '#{polymorphic_model.classify}') AND (SELECT id
              FROM #{polymorphic_model.classify.constantize.table_name}
              WHERE id = NEW.#{relation}_id) ISNULL)
              THEN RAISE(ABORT, 'There is no #{polymorphic_model.classify} with that id.')
          }
        end

        sql << "END; END;"

        strip_non_essential_spaces(sql)
      end

      def generate_delete_constraints(relation, associated_table, polymorphic_model)
        associated_table = associated_table.to_s
        polymorphic_model = polymorphic_model.to_s
        
        sql = %{

          CREATE TRIGGER
            check_#{relation}_#{polymorphic_model.classify.constantize.table_name}_delete_integrity
            BEFORE DELETE ON #{polymorphic_model.classify.constantize.table_name}
            BEGIN
              SELECT CASE
                WHEN ((SELECT id FROM #{associated_table}
                  WHERE #{relation}_type = '#{polymorphic_model.classify}'
                  AND #{relation}_id = OLD.id) NOTNULL) THEN
                    RAISE(ABORT,
                      'There are records in the
                      #{associated_table}
                      table that refer to the
                      #{polymorphic_model.classify.constantize.table_name} record that is
                      attempting to be deleted. Delete the dependent records in
                      the #{associated_table} table
                      first.')
              END;
            END;

        }

        strip_non_essential_spaces(sql)
      end
    end
  end
end

PolymorphicConstraints::Adapter.safe_include :SQLite3Adapter, PolymorphicConstraints::ConnectionAdapters::SQLite3Adapter
