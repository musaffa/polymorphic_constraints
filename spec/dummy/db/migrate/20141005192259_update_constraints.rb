class UpdateConstraints < ActiveRecord::Migration
  def change
    update_polymorphic_constraints :imageable, :pictures
  end
end
