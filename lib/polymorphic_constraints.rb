require 'active_support/concern'
require 'active_support/inflector'
require 'polymorphic_constraints/adapters/postgresql'


module PolymorphicConstraints
  extend ActiveSupport::Concern

  def add_polymorphic_constraints(relation, associated_model, opts = {})
    polymorphic_models = opts.fetch(:polymorphic_models) { get_polymorphic_models(relation) }.map(&:to_s)
    triggers = []
    triggers << PolymorphicConstraints::Adapters::Postgresql.generate_input_constraints(relation, associated_model.to_s, polymorphic_models)
    triggers << PolymorphicConstraints::Adapters::Postgresql.generate_delete_constraints(relation, associated_model.to_s, polymorphic_models)

    triggers.each { |trigger| execute trigger }
  end

  def remove_polymorphic_constraints(relation)
    triggers = []
    triggers << PolymorphicConstraints::Adapters::Postgresql.drop_constraints(relation)

    triggers.each { |trigger| execute trigger }
  end

  private

  def get_polymorphic_models(relation)
    Rails.application.eager_load!
    ActiveRecord::Base.descendants.select do |klass|
      associations = klass.reflect_on_all_associations
      associations.map{ |r| r.options[:as] }.include?(relation)
    end
  end
end

class ActiveRecord::Migration
  include PolymorphicConstraints
end
