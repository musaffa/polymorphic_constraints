require 'spec_helper'

describe PolymorphicConstraints do

  subject { PolymorphicTables.new }

  describe 'add_polymorphic_constraints' do
    it 'requires relation and associated model' do
      expect{ subject.add_polymorphic_constraints(:imageable, :pictures) }.not_to raise_error
    end

    it 'accepts optional hash' do
      expect{ subject.add_polymorphic_constraints(:imageable, :pictures, polymorphic_models: [:product]) }.not_to raise_error
    end
  end

  describe 'remove_polymorphic_constraints' do
    it 'requires relation' do
      expect{ subject.remove_polymorphic_constraints(:imageable) }.not_to raise_error
    end
  end
end
