require 'spec_helper'
require 'polymorphic_constraints/connection_adapters/postgresql_adapter'

describe PolymorphicConstraints::ConnectionAdapters::PostgreSQLAdapter do
  class TestAdapter
    include Support::AdapterHelper
    include PolymorphicConstraints::ConnectionAdapters::PostgreSQLAdapter
  end

  subject { TestAdapter.new }

  it { is_expected.to respond_to(:supports_polymorphic_constraints?) }
  it { is_expected.to respond_to(:add_polymorphic_constraints) }
  it { is_expected.to respond_to(:remove_polymorphic_constraints) }

  describe 'add constraints' do
    it 'returns expected add constraints sql' do
      expect(subject.add_polymorphic_constraints(:imageable, :pictures)).to eql([upsert_triggers_sql, delete_triggers_sql])
    end

    it 'returns expected add constraints sql with polymorphic model options' do
      expect(subject.add_polymorphic_constraints(:imageable, :pictures,
                                                 polymorphic_models: [:employee, :product])).to eql([upsert_triggers_sql, delete_triggers_sql])
    end
  end

  describe 'remove constraints' do
    it 'returns expected drop trigger sql' do
      expect(subject.remove_polymorphic_constraints(:imageable)).to eql(drop_triggers_sql)
    end
  end

  let(:upsert_triggers_sql) do
    subject.strip_non_essential_spaces(%{
      DROP FUNCTION IF EXISTS check_imageable_upsert_integrity()
        CASCADE;

      CREATE FUNCTION check_imageable_upsert_integrity() RETURNS TRIGGER AS '
        BEGIN
          IF NEW.imageable_type = ''Employee'' AND EXISTS (
              SELECT id FROM employees WHERE id = NEW.imageable_id) THEN
            RETURN NEW;

          ELSEIF NEW.imageable_type = ''Product'' AND EXISTS (
              SELECT id FROM products WHERE id = NEW.imageable_id) THEN
            RETURN NEW;

          ELSE
            RAISE EXCEPTION ''No % model with id %.'', NEW.imageable_type, NEW.imageable_id;
            RETURN NULL;
          END IF;
        END'
      LANGUAGE plpgsql;

      CREATE TRIGGER check_imageable_upsert_integrity_trigger
        BEFORE INSERT OR UPDATE ON pictures
        FOR EACH ROW EXECUTE PROCEDURE check_imageable_upsert_integrity();
    })
  end

  let(:delete_triggers_sql) do
    subject.strip_non_essential_spaces(%{
      DROP FUNCTION IF EXISTS check_imageable_delete_integrity()
        CASCADE;

      CREATE FUNCTION check_imageable_delete_integrity()
      RETURNS TRIGGER AS '
        BEGIN
          IF TG_TABLE_NAME = ''employees'' AND EXISTS (
              SELECT id FROM pictures
              WHERE imageable_type = ''Employee'' AND imageable_id = OLD.id) THEN
              RAISE EXCEPTION ''There are records in pictures that refer to the table % with id %. You must delete those records first.'', TG_TABLE_NAME, OLD.id;
            RETURN NULL;

          ELSEIF TG_TABLE_NAME = ''products'' AND EXISTS (
              SELECT id FROM pictures
              WHERE imageable_type = ''Product'' AND imageable_id = OLD.id) THEN
              RAISE EXCEPTION ''There are records in pictures that refer to the table % with id %. You must delete those records first.'', TG_TABLE_NAME, OLD.id;
            RETURN NULL;

          ELSE
            RETURN OLD;
          END IF;
        END'
      LANGUAGE plpgsql;

      CREATE TRIGGER check_employees_delete_integrity_trigger
        BEFORE DELETE ON employees
        FOR EACH ROW EXECUTE PROCEDURE check_imageable_delete_integrity();

      CREATE TRIGGER check_products_delete_integrity_trigger
        BEFORE DELETE ON products
        FOR EACH ROW EXECUTE PROCEDURE check_imageable_delete_integrity();
    })
  end

  let(:drop_triggers_sql) do
    subject.strip_non_essential_spaces(%{
      DROP FUNCTION IF EXISTS check_imageable_upsert_integrity()
        CASCADE;
      DROP FUNCTION IF EXISTS check_imageable_delete_integrity()
        CASCADE;
    })
  end
end