module PolymorphicConstraints
  module ConnectionAdapters
    module Mysql2Adapter
      include CommonAdapter

      private

      def delete_statement(relation, associated_table, polymorphic_model)
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
                  SET MESSAGE_TEXT = 'Polymorphic reference exists.
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
            SET MESSAGE_TEXT = 'Polymorphic record not found. No model by that name.';
        SQL


        polymorphic_models.each do |polymorphic_model|
          sql << <<-SQL
            ELSEIF NEW.#{relation}_type = '#{polymorphic_model.classify}' AND
                   NOT EXISTS (SELECT id FROM #{polymorphic_model.classify.constantize.table_name}
                               WHERE id = NEW.#{relation}_id) THEN

              SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Polymorphic record not found. No #{polymorphic_model.classify} with that id.';
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
