require 'active_support/inflector'
require_relative '../utils/sql_string'

module PolymorphicConstraints
  module ConnectionAdapters
    module PostgreSQLAdapter
      include PolymorphicConstraints::Utils::SqlString

      def supports_polymorphic_constraints?
        true
      end

      def add_polymorphic_constraints(relation, associated_table, options = {})
        polymorphic_models = options.fetch(:polymorphic_models) { get_polymorphic_models(relation) }
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

      def get_polymorphic_models(relation)
        Rails.application.eager_load!
        ActiveRecord::Base.descendants.select do |klass|
          associations = klass.reflect_on_all_associations
          associations.map{ |r| r.options[:as] }.include?(relation.to_sym)
        end
      end

      def generate_upsert_constraints(relation, associated_table, polymorphic_models)
        associated_table = associated_table.to_s
        polymorphic_models = polymorphic_models.map(&:to_s)

        sql = "DROP FUNCTION IF EXISTS check_#{relation}_upsert_integrity()
                 CASCADE;"

        sql << %{
          CREATE FUNCTION check_#{relation}_upsert_integrity()
          RETURNS TRIGGER AS '
            BEGIN
              IF NEW.#{relation}_type = ''#{polymorphic_models[0].classify}'' AND EXISTS (
                  SELECT id FROM #{polymorphic_models[0].classify.constantize.table_name}
                  WHERE id = NEW.#{relation}_id) THEN

                RETURN NEW;
        }

        polymorphic_models[1..-1].each do |polymorphic_model|
          sql << %{
            ELSEIF NEW.#{relation}_type = ''#{polymorphic_model.classify}'' AND EXISTS (
                SELECT id FROM #{polymorphic_model.classify.constantize.table_name}
                WHERE id = NEW.#{relation}_id) THEN

              RETURN NEW;
          }
        end

        sql << %{
            ELSE
              RAISE EXCEPTION ''No % model with id %.'', NEW.#{relation}_type, NEW.#{relation}_id;
              RETURN NULL;
            END IF;
          END'
          LANGUAGE plpgsql;

          CREATE TRIGGER check_#{relation}_upsert_integrity_trigger
          BEFORE INSERT OR UPDATE ON #{associated_table}
          FOR EACH ROW
          EXECUTE PROCEDURE check_#{relation}_upsert_integrity();
        }

        strip_non_essential_spaces(sql)
      end

      def generate_delete_constraints(relation, associated_table, polymorphic_models)
        associated_table = associated_table.to_s
        polymorphic_models = polymorphic_models.map(&:to_s)

        sql = "DROP FUNCTION IF EXISTS check_#{relation}_delete_integrity()
                 CASCADE;"
        sql << %{
          CREATE FUNCTION check_#{relation}_delete_integrity()
          RETURNS TRIGGER AS '
            BEGIN
              IF TG_TABLE_NAME = ''#{polymorphic_models[0].classify.constantize.table_name}'' AND
              EXISTS (
                  SELECT id FROM #{associated_table}
                  WHERE #{relation}_type = ''#{polymorphic_models[0].classify}''
                  AND #{relation}_id = OLD.id) THEN

                RAISE EXCEPTION ''There are records in #{associated_table} that refer to the
                table % with id %. You must delete those records first.'', TG_TABLE_NAME, OLD.id;
                RETURN NULL;
        }

        polymorphic_models[1..-1].each do |polymorphic_model|
          sql << %{
            ELSEIF TG_TABLE_NAME = ''#{polymorphic_model.classify.constantize.table_name}'' AND
            EXISTS (
                SELECT id FROM #{associated_table}
                WHERE #{relation}_type = ''#{polymorphic_model.classify}''
                AND #{relation}_id = OLD.id) THEN

              RAISE EXCEPTION ''There are records in #{associated_table} that refer to the
              table % with id %. You must delete those records first.'', TG_TABLE_NAME, OLD.id;
              RETURN NULL;
          }
        end

        sql << %{
              ELSE
                RETURN OLD;
              END IF;
            END'
          LANGUAGE plpgsql;
        }

        polymorphic_models.each do |polymorphic_model|
          table_name = polymorphic_model.classify.constantize.table_name

          sql << %{
            CREATE TRIGGER check_#{table_name}_delete_integrity_trigger
            BEFORE DELETE ON #{table_name}
            FOR EACH ROW EXECUTE PROCEDURE check_#{relation}_delete_integrity();
          }
        end

        strip_non_essential_spaces(sql)
      end

      def drop_constraints(relation)
        sql = %{
          DROP FUNCTION IF EXISTS check_#{relation}_upsert_integrity()
            CASCADE;
          DROP FUNCTION IF EXISTS check_#{relation}_delete_integrity()
            CASCADE;
        }

        strip_non_essential_spaces(sql)
      end
    end
  end
end

PolymorphicConstraints::Adapter.safe_include :PostgreSQLAdapter, PolymorphicConstraints::ConnectionAdapters::PostgreSQLAdapter
