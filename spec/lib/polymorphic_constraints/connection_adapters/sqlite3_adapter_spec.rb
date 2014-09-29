require 'spec_helper'
require 'polymorphic_constraints/connection_adapters/sqlite3_adapter'

describe PolymorphicConstraints::ConnectionAdapters::SQLite3Adapter do
  class TestAdapter
    include Support::AdapterHelper
    include PolymorphicConstraints::ConnectionAdapters::SQLite3Adapter
  end

  subject { TestAdapter.new }

  it { is_expected.to respond_to(:supports_polymorphic_constraints?) }
  it { is_expected.to respond_to(:add_polymorphic_constraints) }
  it { is_expected.to respond_to(:remove_polymorphic_constraints) }

  describe 'add constraints' do
    it 'returns expected add constraints sql' do
      expect(subject.add_polymorphic_constraints(:imageable, :pictures)).to eql([create_triggers_sql,
                                                                                 update_triggers_sql,
                                                                                 delete_employees_triggers_sql,
                                                                                 delete_products_triggers_sql])
    end

    it 'returns expected add constraints sql with polymorphic model options' do
      expect(subject.add_polymorphic_constraints(:imageable, :pictures,
                                                 polymorphic_models: [:employee, :product])).to eql([create_triggers_sql,
                                                                                                     update_triggers_sql,
                                                                                                     delete_employees_triggers_sql,
                                                                                                     delete_products_triggers_sql])
    end
  end

  describe 'remove constraints' do
    it 'returns expected drop trigger sql' do
      expect(subject.remove_polymorphic_constraints(:imageable)).to eql(drop_triggers_sql)
    end
  end

  let(:create_triggers_sql) do
    subject.strip_non_essential_spaces(%{
      DROP TRIGGER IF EXISTS check_imageable_create_integrity;

      CREATE TRIGGER check_imageable_create_integrity
      BEFORE INSERT ON pictures
      BEGIN
        SELECT CASE
          WHEN (NEW.imageable_type != 'Employee' AND NEW.imageable_type != 'Product' ) THEN RAISE(ABORT, 'There is no model by that name.')
          WHEN ((NEW.imageable_type = 'Employee') AND (SELECT id FROM employees WHERE id = NEW.imageable_id) ISNULL) THEN RAISE(ABORT, 'There is no Employee with that id.')
          WHEN ((NEW.imageable_type = 'Product') AND (SELECT id FROM products WHERE id = NEW.imageable_id) ISNULL) THEN RAISE(ABORT, 'There is no Product with that id.')
        END;
      END;
    })
  end

  let(:update_triggers_sql) do
    subject.strip_non_essential_spaces(%{
      DROP TRIGGER IF EXISTS check_imageable_update_integrity;

      CREATE TRIGGER check_imageable_update_integrity
      BEFORE UPDATE ON pictures
      BEGIN
        SELECT CASE
          WHEN (NEW.imageable_type != 'Employee' AND NEW.imageable_type != 'Product' ) THEN RAISE(ABORT, 'There is no model by that name.')
          WHEN ((NEW.imageable_type = 'Employee') AND (SELECT id FROM employees WHERE id = NEW.imageable_id) ISNULL) THEN RAISE(ABORT, 'There is no Employee with that id.')
          WHEN ((NEW.imageable_type = 'Product') AND (SELECT id FROM products WHERE id = NEW.imageable_id) ISNULL) THEN RAISE(ABORT, 'There is no Product with that id.')
        END;
      END;
    })
  end

  let(:delete_employees_triggers_sql) do
    subject.strip_non_essential_spaces(%{
      DROP TRIGGER IF EXISTS check_imageable_employees_delete_integrity;

      CREATE TRIGGER check_imageable_employees_delete_integrity
        BEFORE DELETE ON employees
        BEGIN
          SELECT CASE
            WHEN ((SELECT id FROM pictures WHERE imageable_type = 'Employee' AND imageable_id = OLD.id) NOTNULL) THEN
              RAISE(ABORT, 'There are records in the pictures table that refer to the employees record that is attempting to be deleted. Delete the dependent records in the pictures table first.')
          END;
        END;
    })
  end

  let(:delete_products_triggers_sql) do
    subject.strip_non_essential_spaces(%{
      DROP TRIGGER IF EXISTS check_imageable_products_delete_integrity;

      CREATE TRIGGER check_imageable_products_delete_integrity
        BEFORE DELETE ON products
        BEGIN
          SELECT CASE
            WHEN ((SELECT id FROM pictures WHERE imageable_type = 'Product' AND imageable_id = OLD.id) NOTNULL) THEN
              RAISE(ABORT, 'There are records in the pictures table that refer to the products record that is attempting to be deleted. Delete the dependent records in the pictures table first.')
          END;
        END;
    })
  end

  let(:drop_triggers_sql) do
    subject.strip_non_essential_spaces(%{
      DROP TRIGGER IF EXISTS check_imageable_create_integrity;
      DROP TRIGGER IF EXISTS check_imageable_update_integrity;
      DROP TRIGGER IF EXISTS check_imageable_employees_delete_integrity;
      DROP TRIGGER IF EXISTS check_imageable_products_delete_integrity;
    })
  end
end
