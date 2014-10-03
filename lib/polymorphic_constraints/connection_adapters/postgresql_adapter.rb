require 'active_support/inflector'
require_relative '../utils/sql_string'
require_relative '../utils/model_finder'

module PolymorphicConstraints
  module ConnectionAdapters
    module PostgreSQLAdapter
      include PolymorphicConstraints::Utils::SqlString
      include PolymorphicConstraints::Utils::ModelFinder

      def supports_polymorphic_constraints?
        true
      end

      def add_polymorphic_constraints(relation, associated_table, options = {})
        search_strategy = options.fetch(:search_strategy, :active_record_descendants)
        polymorphic_models = options.fetch(:polymorphic_models) { get_polymorphic_models(relation, search_strategy) }
        statements = []
        statements << generate_upsert_constraints(relation, associated_table, polymorphic_models)
        statements << generate_delete_constraints(relation, associated_table, polymorphic_models)

        statements.each { |statement| execute statement }
      end

      def remove_polymorphic_constraints(relation, options = {})
        statement = drop_constraints(relation)
        execute statement
      end

      private

      def generate_upsert_constraints(relation, associated_table, polymorphic_models)
        associated_table = associated_table.to_s
        polymorphic_models = polymorphic_models.map(&:to_s)

        sql = <<-SQL
          DROP FUNCTION IF EXISTS check_#{relation}_upsert_integrity()
            CASCADE;
        SQL

        sql << <<-SQL
          CREATE FUNCTION check_#{relation}_upsert_integrity()
            RETURNS TRIGGER AS '
              BEGIN
                IF NEW.#{relation}_type = ''#{polymorphic_models[0].classify}'' AND
                   EXISTS (SELECT id FROM #{polymorphic_models[0].classify.constantize.table_name}
                           WHERE id = NEW.#{relation}_id) THEN

                  RETURN NEW;
        SQL

        polymorphic_models[1..-1].each do |polymorphic_model|
          sql << <<-SQL
            ELSEIF NEW.#{relation}_type = ''#{polymorphic_model.classify}'' AND
                   EXISTS (SELECT id FROM #{polymorphic_model.classify.constantize.table_name}
                           WHERE id = NEW.#{relation}_id) THEN

              RETURN NEW;
          SQL
        end

        sql << <<-SQL
            ELSE
              RAISE EXCEPTION ''Polymorphic Constraints error. Polymorphic record not found.
                                No % model with id %.'', NEW.#{relation}_type, NEW.#{relation}_id;
              RETURN NULL;
            END IF;
          END'
          LANGUAGE plpgsql;

          CREATE TRIGGER check_#{relation}_upsert_integrity_trigger
            BEFORE INSERT OR UPDATE ON #{associated_table}
            FOR EACH ROW
            EXECUTE PROCEDURE check_#{relation}_upsert_integrity();
        SQL

        strip_non_essential_spaces(sql)
      end

      def generate_delete_constraints(relation, associated_table, polymorphic_models)
        associated_table = associated_table.to_s
        polymorphic_models = polymorphic_models.map(&:to_s)

        sql = <<-SQL
          DROP FUNCTION IF EXISTS check_#{relation}_delete_integrity()
            CASCADE;
        SQL

        sql << <<-SQL
          CREATE FUNCTION check_#{relation}_delete_integrity()
            RETURNS TRIGGER AS '
              BEGIN
                IF TG_TABLE_NAME = ''#{polymorphic_models[0].classify.constantize.table_name}'' AND
                   EXISTS (SELECT id FROM #{associated_table}
                           WHERE #{relation}_type = ''#{polymorphic_models[0].classify}''
                           AND #{relation}_id = OLD.id) THEN

                  RAISE EXCEPTION ''Polymorphic Constraints error. Polymorphic reference exists.
                                    There are records in #{associated_table} that refer to the table % with id %.
                                    You must delete those records of table #{associated_table} first.'', TG_TABLE_NAME, OLD.id;
                  RETURN NULL;
        SQL

        polymorphic_models[1..-1].each do |polymorphic_model|
          sql << <<-SQL
            ELSEIF TG_TABLE_NAME = ''#{polymorphic_model.classify.constantize.table_name}'' AND
                   EXISTS (SELECT id FROM #{associated_table}
                           WHERE #{relation}_type = ''#{polymorphic_model.classify}''
                           AND #{relation}_id = OLD.id) THEN

              RAISE EXCEPTION ''Polymorphic Constraints error. Polymorphic reference exists.
                                There are records in #{associated_table} that refer to the table % with id %.
                                You must delete those records of table #{associated_table} first.'', TG_TABLE_NAME, OLD.id;
              RETURN NULL;
          SQL
        end

        sql << <<-SQL
              ELSE
                RETURN OLD;
              END IF;
            END'
          LANGUAGE plpgsql;
        SQL

        polymorphic_models.each do |polymorphic_model|
          table_name = polymorphic_model.classify.constantize.table_name

          sql << <<-SQL
            CREATE TRIGGER check_#{relation}_#{table_name}_delete_integrity_trigger
              BEFORE DELETE ON #{table_name}
              FOR EACH ROW
              EXECUTE PROCEDURE check_#{relation}_delete_integrity();
          SQL
        end

        strip_non_essential_spaces(sql)
      end

      def drop_constraints(relation)
        sql = <<-SQL
          DROP FUNCTION IF EXISTS check_#{relation}_upsert_integrity()
            CASCADE;
          DROP FUNCTION IF EXISTS check_#{relation}_delete_integrity()
            CASCADE;
        SQL

        strip_non_essential_spaces(sql)
      end
    end
  end
end

PolymorphicConstraints::Adapter.safe_include :PostgreSQLAdapter, PolymorphicConstraints::ConnectionAdapters::PostgreSQLAdapter
