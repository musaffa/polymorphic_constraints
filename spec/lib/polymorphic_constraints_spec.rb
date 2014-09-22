require 'spec_helper'

describe PolymorphicConstraints do

  before do
    class DummyMigration < ActiveRecord::Migration
      def change
      end
    end
  end

  subject { DummyMigration.new }

  it { is_expected.to respond_to :add_polymorphic_constraints }
end