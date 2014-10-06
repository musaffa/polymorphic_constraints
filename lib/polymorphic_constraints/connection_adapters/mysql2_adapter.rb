require 'active_support/inflector'
require_relative '../utils/sql_string'
require_relative '../utils/polymorphic_model_finder'

module PolymorphicConstraints
  module ConnectionAdapters
    module Mysql2Adapter
      include PolymorphicConstraints::Utils::SqlString
      include PolymorphicConstraints::Utils::PolymorphicModelFinder

      def supports_polymorphic_constraints?
        true
      end

      def add_polymorphic_constraints(relation, associated_table, options = {})
        polymorphic_models = options.fetch(:polymorphic_models) { get_polymorphic_models(relation) }

        statements = constraints_remove_statements(relation)
        statements << generate_insert_constraints(relation, associated_table, polymorphic_models)
        statements << generate_update_constraints(relation, associated_table, polymorphic_models)

        polymorphic_models.each do |polymorphic_model|
          statements << generate_delete_constraints(relation, associated_table, polymorphic_model)
        end

        statements.each { |statement| execute statement }
      end

      def remove_polymorphic_constraints(relation)
        statements = constraints_remove_statements(relation)
        statements.each { |statement| execute statement }
      end

      alias_method :update_polymorphic_constraints, :add_polymorphic_constraints

      private

      def constraints_remove_statements(relation)
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

        sql = <<-SQL
          CREATE TRIGGER check_#{relation}_update_integrity
            BEFORE UPDATE ON #{associated_table}
        SQL

        sql << common_upsert_sql(relation, polymorphic_models)

        strip_non_essential_spaces(sql)
      end

      def generate_delete_constraints(relation, associated_table, polymorphic_model)
        associated_table = associated_table.to_s
        polymorphic_model = polymorphic_model.to_s

        sql = <<-SQL
          CREATE TRIGGER check_#{relation}_#{polymorphic_model.classify.constantize.table_name}_delete_integrity
            BEFORE DELETE ON #{polymorphic_model.classify.constantize.table_name}
            FOR EACH ROW
            BEGIN
              IF EXISTS (SELECT id FROM #{associated_table}
                         WHERE #{relation}_type = '#{polymorphic_model.classify}'
                         AND #{relation}_id = OLD.id) THEN
                SIGNAL SQLSTATE '45000'
                  SET MESSAGE_TEXT = 'Polymorphic Constraints error. Polymorphic reference exists.
                                      There are records in the #{associated_table} table that refer to the
                                      table #{polymorphic_model.classify.constantize.table_name}.
                                      You must delete those records of table #{associated_table} first.';
              END IF;
            END;
        SQL

        strip_non_essential_spaces(sql)
      end

      def common_upsert_sql(relation, polymorphic_models)
        polymorphic_models = polymorphic_models.map(&:to_s)

        sql = <<-SQL
          FOR EACH ROW
          BEGIN
            IF
        SQL

        polymorphic_models.each do |polymorphic_model|
          sql << <<-SQL
            NEW.#{relation}_type != '#{polymorphic_model.classify}'
          SQL

          unless polymorphic_model == polymorphic_models.last
            sql << <<-SQL
              AND
            SQL
          end
        end

        sql << <<-SQL
          THEN SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Polymorphic Constraints error. Polymorphic record not found. No model by that name.';
        SQL


        polymorphic_models.each do |polymorphic_model|
          sql << <<-SQL
            ELSEIF NEW.#{relation}_type = '#{polymorphic_model.classify}' AND
                   NOT EXISTS (SELECT id FROM #{polymorphic_model.classify.constantize.table_name}
                               WHERE id = NEW.#{relation}_id) THEN

              SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Polymorphic Constraints error. Polymorphic record not found.
                                    No #{polymorphic_model.classify} with that id.';
          SQL
        end

        sql << <<-SQL
            END IF;
          END;
        SQL
      end
    end
  end
end

PolymorphicConstraints::Adapter.safe_include :Mysql2Adapter, PolymorphicConstraints::ConnectionAdapters::Mysql2Adapter
