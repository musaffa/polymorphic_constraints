require 'spec_helper'
require 'polymorphic_constraints/connection_adapters/mysql2_adapter'

describe PolymorphicConstraints::ConnectionAdapters::Mysql2Adapter do

  class MysqlTestAdapter
    include Support::AdapterHelper
    include PolymorphicConstraints::ConnectionAdapters::Mysql2Adapter
  end

  subject { MysqlTestAdapter.new }

  it { is_expected.to respond_to(:supports_polymorphic_constraints?) }
  it { is_expected.to respond_to(:add_polymorphic_constraints) }
  it { is_expected.to respond_to(:remove_polymorphic_constraints) }

  describe 'add constraints' do
    it 'defaults to active_record_descendants search strategy' do
      expect(subject.add_polymorphic_constraints(:imageable, :pictures)).to eql([drop_create_trigger_sql,
                                                                                 drop_update_trigger_sql,
                                                                                 drop_employees_delete_trigger_sql,
                                                                                 drop_products_delete_trigger_sql,
                                                                                 create_trigger_sql,
                                                                                 update_trigger_sql,
                                                                                 employees_delete_trigger_sql,
                                                                                 products_delete_trigger_sql])
    end

    it 'returns expected add constraints sql with polymorphic model options' do
      expect(subject.add_polymorphic_constraints(:imageable, :pictures,
                                                 polymorphic_models: [:employee])).to eql([drop_create_trigger_sql,
                                                                                           drop_update_trigger_sql,
                                                                                           drop_employees_delete_trigger_sql,
                                                                                           drop_products_delete_trigger_sql,
                                                                                           create_trigger_sql_only_employee,
                                                                                           update_trigger_sql_only_employee,
                                                                                           employees_delete_trigger_sql])
    end
  end

  describe 'remove constraints' do
    it 'defaults to active_record_descendants search strategy' do
      expect(subject.remove_polymorphic_constraints(:imageable)).to eql([drop_create_trigger_sql,
                                                                         drop_update_trigger_sql,
                                                                         drop_employees_delete_trigger_sql,
                                                                         drop_products_delete_trigger_sql])
    end
  end

  let(:drop_create_trigger_sql) { 'DROP TRIGGER IF EXISTS check_imageable_insert_integrity;' }
  let(:drop_update_trigger_sql) { 'DROP TRIGGER IF EXISTS check_imageable_update_integrity;' }

  let(:drop_employees_delete_trigger_sql) { 'DROP TRIGGER IF EXISTS check_imageable_employees_delete_integrity;' }

  let(:employees_delete_trigger_sql) do
    subject.strip_non_essential_spaces(%{
      CREATE TRIGGER check_imageable_employees_delete_integrity
        BEFORE DELETE ON employees
        FOR EACH ROW
        BEGIN
          IF EXISTS (SELECT id FROM pictures
                     WHERE imageable_type = 'Employee'
                     AND imageable_id = OLD.id) THEN
            SIGNAL SQLSTATE '45000'
              SET MESSAGE_TEXT = 'Polymorphic reference exists.
                                  There are records in the pictures table that refer to the table employees.
                                  You must delete those records of table pictures first.';
          END IF;
        END;
    })
  end

  let(:drop_products_delete_trigger_sql) { 'DROP TRIGGER IF EXISTS check_imageable_products_delete_integrity;' }

  let(:products_delete_trigger_sql) do
    subject.strip_non_essential_spaces(%{
      CREATE TRIGGER check_imageable_products_delete_integrity
        BEFORE DELETE ON products
        FOR EACH ROW
        BEGIN
          IF EXISTS (SELECT id FROM pictures
                     WHERE imageable_type = 'Product'
                     AND imageable_id = OLD.id) THEN
            SIGNAL SQLSTATE '45000'
              SET MESSAGE_TEXT = 'Polymorphic reference exists.
                                  There are records in the pictures table that refer to the table products.
                                  You must delete those records of table pictures first.';
          END IF;
        END;
    })
  end

  let(:create_trigger_sql) do
    subject.strip_non_essential_spaces(%{
      CREATE TRIGGER check_imageable_insert_integrity
      BEFORE INSERT ON pictures
      FOR EACH ROW
      BEGIN
        IF NEW.imageable_type != 'Employee' AND NEW.imageable_type != 'Product' THEN
          SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Polymorphic record not found. No model by that name.';
        ELSEIF NEW.imageable_type = 'Employee' AND NOT EXISTS (SELECT id FROM employees WHERE id = NEW.imageable_id) THEN
          SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Polymorphic record not found. No Employee with that id.';
        ELSEIF NEW.imageable_type = 'Product' AND NOT EXISTS (SELECT id FROM products WHERE id = NEW.imageable_id) THEN
          SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Polymorphic record not found. No Product with that id.';
        END IF;
      END;
    })
  end

  let(:update_trigger_sql) do
    subject.strip_non_essential_spaces(%{
      CREATE TRIGGER check_imageable_update_integrity
      BEFORE UPDATE ON pictures
      FOR EACH ROW
      BEGIN
        IF NEW.imageable_type != 'Employee' AND NEW.imageable_type != 'Product' THEN
          SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Polymorphic record not found. No model by that name.';
        ELSEIF NEW.imageable_type = 'Employee' AND NOT EXISTS (SELECT id FROM employees WHERE id = NEW.imageable_id) THEN
          SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Polymorphic record not found. No Employee with that id.';
        ELSEIF NEW.imageable_type = 'Product' AND NOT EXISTS (SELECT id FROM products WHERE id = NEW.imageable_id) THEN
          SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Polymorphic record not found. No Product with that id.';
        END IF;
      END;
    })
  end

  let(:create_trigger_sql_only_employee) do
    subject.strip_non_essential_spaces(%{
      CREATE TRIGGER check_imageable_insert_integrity
      BEFORE INSERT ON pictures
      FOR EACH ROW
      BEGIN
        IF NEW.imageable_type != 'Employee' THEN
          SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Polymorphic record not found. No model by that name.';
        ELSEIF NEW.imageable_type = 'Employee' AND NOT EXISTS (SELECT id FROM employees WHERE id = NEW.imageable_id) THEN
          SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Polymorphic record not found. No Employee with that id.';
        END IF;
      END;
    })
  end

  let(:update_trigger_sql_only_employee) do
    subject.strip_non_essential_spaces(%{
      CREATE TRIGGER check_imageable_update_integrity
      BEFORE UPDATE ON pictures
      FOR EACH ROW
      BEGIN
        IF NEW.imageable_type != 'Employee' THEN
          SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Polymorphic record not found. No model by that name.';
        ELSEIF NEW.imageable_type = 'Employee' AND NOT EXISTS (SELECT id FROM employees WHERE id = NEW.imageable_id) THEN
          SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Polymorphic record not found. No Employee with that id.';
        END IF;
      END;
    })
  end
end
