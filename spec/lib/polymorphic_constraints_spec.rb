require 'spec_helper'

describe PolymorphicConstraints do

  before do
    class Employee < ActiveRecord::Base
      has_many :pictures, as: :imageable
    end

    class Product < ActiveRecord::Base
      has_many :pictures, as: :imageable
    end

    class Picture < ActiveRecord::Base
      belongs_to :imageable, polymorphic: true
    end

    class DummyMigration < ActiveRecord::Migration
      def change
      end
    end
  end

  subject { DummyMigration.new }

  it { is_expected.to respond_to :add_polymorphic_constraints }
  it { is_expected.to respond_to :remove_polymorphic_constraints }

  describe 'add_polymorphic_constraints' do
    it 'requires relation and associated model' do
      expect{ subject.add_polymorphic_constraints(:imageable, :picture) }.not_to raise_error
    end

    it 'accepts optional hash' do
      expect{ subject.add_polymorphic_constraints(:imageable, :picture, polymorphic_models: [:product]) }.not_to raise_error
    end
  end

  describe 'remove_polymorphic_constraints' do
    it 'requires relation' do
      expect{ subject.remove_polymorphic_constraints(:imageable) }.not_to raise_error
    end
  end
end