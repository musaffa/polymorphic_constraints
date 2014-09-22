module PolymorphicConstraints
  def add_polymorphic_constraints(opts)

  end
end

class ActiveRecord::Migration
  include PolymorphicConstraints
end
