require 'spec_helper'
require 'polymorphic_constraints/connection_adapters/sqlite3_adapter'

describe PolymorphicConstraints::ConnectionAdapters::SQLite3Adapter do

  class Member < ActiveRecord::Base
    has_many :pictures, as: :imageable, dependent: :destroy
  end

  class TestAdapter
    include Support::AdapterHelper
    include PolymorphicConstraints::ConnectionAdapters::SQLite3Adapter
  end

  subject { TestAdapter.new }

  it { is_expected.to respond_to(:supports_polymorphic_constraints?) }
  it { is_expected.to respond_to(:add_polymorphic_constraints) }
  it { is_expected.to respond_to(:remove_polymorphic_constraints) }

  describe 'add constraints' do
    context 'search strategy' do
      it 'defaults to active_record_descendants search strategy' do
        expect(subject.add_polymorphic_constraints(:imageable, :pictures)).to eql([drop_create_trigger_sql,
                                                                                   create_trigger_sql_with_member,
                                                                                   drop_update_trigger_sql,
                                                                                   update_trigger_sql_with_member,
                                                                                   drop_members_delete_trigger_sql,
                                                                                   members_delete_trigger_sql,
                                                                                   drop_employees_delete_trigger_sql,
                                                                                   employees_delete_trigger_sql,
                                                                                   drop_products_delete_trigger_sql,
                                                                                   products_delete_trigger_sql])
      end

      it 'returns expected add constraints sql with models_directory search strategy' do
        expect(subject.add_polymorphic_constraints(:imageable, :pictures,
                                                   search_strategy: :models_directory)).to eql([drop_create_trigger_sql,
                                                                                                create_trigger_sql,
                                                                                                drop_update_trigger_sql,
                                                                                                update_trigger_sql,
                                                                                                drop_employees_delete_trigger_sql,
                                                                                                employees_delete_trigger_sql,
                                                                                                drop_products_delete_trigger_sql,
                                                                                                products_delete_trigger_sql])
      end

      it 'returns expected add constraints sql with polymorphic model options' do
        expect(subject.add_polymorphic_constraints(:imageable, :pictures,
                                                   polymorphic_models: [:employee])).to eql([drop_create_trigger_sql,
                                                                                             create_trigger_sql_only_employee,
                                                                                             drop_update_trigger_sql,
                                                                                             update_trigger_sql_only_employee,
                                                                                             drop_employees_delete_trigger_sql,
                                                                                             employees_delete_trigger_sql])
      end
    end

  end

  describe 'remove constraints' do
    context 'search strategy' do
      it 'defaults to active_record_descendants search strategy' do
        expect(subject.remove_polymorphic_constraints(:imageable)).to eql([drop_create_trigger_sql,
                                                                           drop_update_trigger_sql,
                                                                           drop_members_delete_trigger_sql,
                                                                           drop_employees_delete_trigger_sql,
                                                                           drop_products_delete_trigger_sql])
      end

      it 'returns expected drop constraints sql with models_directory search strategy' do
        expect(subject.remove_polymorphic_constraints(:imageable,
                                                      search_strategy: :models_directory)).to eql([drop_create_trigger_sql,
                                                                                                   drop_update_trigger_sql,
                                                                                                   drop_employees_delete_trigger_sql,
                                                                                                   drop_products_delete_trigger_sql])
      end
    end
  end

  let(:drop_create_trigger_sql) { 'DROP TRIGGER IF EXISTS check_imageable_insert_integrity;' }

  let(:create_trigger_sql) do
    subject.strip_non_essential_spaces(%{
      CREATE TRIGGER check_imageable_insert_integrity
      BEFORE INSERT ON pictures
      BEGIN
        SELECT CASE
          WHEN (NEW.imageable_type != 'Employee' AND NEW.imageable_type != 'Product' ) THEN
            RAISE(ABORT, 'There is no model by that name.')
          WHEN ((NEW.imageable_type = 'Employee') AND NOT EXISTS (SELECT id FROM employees WHERE id = NEW.imageable_id)) THEN
            RAISE(ABORT, 'There is no Employee with that id.')
          WHEN ((NEW.imageable_type = 'Product') AND NOT EXISTS (SELECT id FROM products WHERE id = NEW.imageable_id)) THEN
            RAISE(ABORT, 'There is no Product with that id.')
        END;
      END;
    })
  end

  let(:drop_update_trigger_sql) { 'DROP TRIGGER IF EXISTS check_imageable_update_integrity;' }

  let(:update_trigger_sql) do
    subject.strip_non_essential_spaces(%{
      CREATE TRIGGER check_imageable_update_integrity
      BEFORE UPDATE ON pictures
      BEGIN
        SELECT CASE
          WHEN (NEW.imageable_type != 'Employee' AND NEW.imageable_type != 'Product' ) THEN
            RAISE(ABORT, 'There is no model by that name.')
          WHEN ((NEW.imageable_type = 'Employee') AND NOT EXISTS (SELECT id FROM employees WHERE id = NEW.imageable_id)) THEN
            RAISE(ABORT, 'There is no Employee with that id.')
          WHEN ((NEW.imageable_type = 'Product') AND NOT EXISTS (SELECT id FROM products WHERE id = NEW.imageable_id)) THEN
            RAISE(ABORT, 'There is no Product with that id.')
        END;
      END;
    })
  end

  let(:drop_members_delete_trigger_sql) { 'DROP TRIGGER IF EXISTS check_imageable_members_delete_integrity;' }

  let(:members_delete_trigger_sql) do
    subject.strip_non_essential_spaces(%{
      CREATE TRIGGER check_imageable_members_delete_integrity
        BEFORE DELETE ON members
        BEGIN
          SELECT CASE
            WHEN EXISTS (SELECT id FROM pictures WHERE imageable_type = 'Member' AND imageable_id = OLD.id) THEN
              RAISE(ABORT, 'There are records in the pictures table that refer to the table members.
                            You must delete those records of table pictures first.')
          END;
        END;
    })
  end

  let(:drop_employees_delete_trigger_sql) { 'DROP TRIGGER IF EXISTS check_imageable_employees_delete_integrity;' }

  let(:employees_delete_trigger_sql) do
    subject.strip_non_essential_spaces(%{
      CREATE TRIGGER check_imageable_employees_delete_integrity
        BEFORE DELETE ON employees
        BEGIN
          SELECT CASE
            WHEN EXISTS (SELECT id FROM pictures WHERE imageable_type = 'Employee' AND imageable_id = OLD.id) THEN
              RAISE(ABORT, 'There are records in the pictures table that refer to the table employees.
                            You must delete those records of table pictures first.')
          END;
        END;
    })
  end

  let(:drop_products_delete_trigger_sql) { 'DROP TRIGGER IF EXISTS check_imageable_products_delete_integrity;' }

  let(:products_delete_trigger_sql) do
    subject.strip_non_essential_spaces(%{
      CREATE TRIGGER check_imageable_products_delete_integrity
        BEFORE DELETE ON products
        BEGIN
          SELECT CASE
            WHEN EXISTS (SELECT id FROM pictures WHERE imageable_type = 'Product' AND imageable_id = OLD.id) THEN
              RAISE(ABORT, 'There are records in the pictures table that refer to the table products.
                            You must delete those records of table pictures first.')
          END;
        END;
    })
  end

  let(:create_trigger_sql_with_member) do
    subject.strip_non_essential_spaces(%{
      CREATE TRIGGER check_imageable_insert_integrity
      BEFORE INSERT ON pictures
      BEGIN
        SELECT CASE
          WHEN (NEW.imageable_type != 'Member' AND NEW.imageable_type != 'Employee' AND NEW.imageable_type != 'Product' ) THEN
            RAISE(ABORT, 'There is no model by that name.')
          WHEN ((NEW.imageable_type = 'Member') AND NOT EXISTS (SELECT id FROM members WHERE id = NEW.imageable_id)) THEN
            RAISE(ABORT, 'There is no Member with that id.')
          WHEN ((NEW.imageable_type = 'Employee') AND NOT EXISTS (SELECT id FROM employees WHERE id = NEW.imageable_id)) THEN
            RAISE(ABORT, 'There is no Employee with that id.')
          WHEN ((NEW.imageable_type = 'Product') AND NOT EXISTS (SELECT id FROM products WHERE id = NEW.imageable_id)) THEN
            RAISE(ABORT, 'There is no Product with that id.')
        END;
      END;
    })
  end

  let(:update_trigger_sql_with_member) do
    subject.strip_non_essential_spaces(%{
      CREATE TRIGGER check_imageable_update_integrity
      BEFORE UPDATE ON pictures
      BEGIN
        SELECT CASE
          WHEN (NEW.imageable_type != 'Member' AND NEW.imageable_type != 'Employee' AND NEW.imageable_type != 'Product' ) THEN
            RAISE(ABORT, 'There is no model by that name.')
          WHEN ((NEW.imageable_type = 'Member') AND NOT EXISTS (SELECT id FROM members WHERE id = NEW.imageable_id)) THEN
            RAISE(ABORT, 'There is no Member with that id.')
          WHEN ((NEW.imageable_type = 'Employee') AND NOT EXISTS (SELECT id FROM employees WHERE id = NEW.imageable_id)) THEN
            RAISE(ABORT, 'There is no Employee with that id.')
          WHEN ((NEW.imageable_type = 'Product') AND NOT EXISTS (SELECT id FROM products WHERE id = NEW.imageable_id)) THEN
            RAISE(ABORT, 'There is no Product with that id.')
        END;
      END;
    })
  end

  let(:create_trigger_sql_only_employee) do
    subject.strip_non_essential_spaces(%{
      CREATE TRIGGER check_imageable_insert_integrity
      BEFORE INSERT ON pictures
      BEGIN
        SELECT CASE
          WHEN (NEW.imageable_type != 'Employee' ) THEN
            RAISE(ABORT, 'There is no model by that name.')
          WHEN ((NEW.imageable_type = 'Employee') AND NOT EXISTS (SELECT id FROM employees WHERE id = NEW.imageable_id)) THEN
            RAISE(ABORT, 'There is no Employee with that id.')
        END;
      END;
    })
  end

  let(:update_trigger_sql_only_employee) do
    subject.strip_non_essential_spaces(%{
      CREATE TRIGGER check_imageable_update_integrity
      BEFORE UPDATE ON pictures
      BEGIN
        SELECT CASE
          WHEN (NEW.imageable_type != 'Employee' ) THEN
            RAISE(ABORT, 'There is no model by that name.')
          WHEN ((NEW.imageable_type = 'Employee') AND NOT EXISTS (SELECT id FROM employees WHERE id = NEW.imageable_id)) THEN
            RAISE(ABORT, 'There is no Employee with that id.')
        END;
      END;
    })
  end
end
