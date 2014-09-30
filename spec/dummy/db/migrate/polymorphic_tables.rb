class PolymorphicTables < ActiveRecord::Migration
  def change
    create_table :employees do |t|
      t.timestamps
    end

    create_table :products do |t|
      t.timestamps
    end

    create_table :pictures do |t|
      t.references :imageable, polymorphic: true
      t.timestamps
    end

    add_polymorphic_constraints :imageable, :pictures
  end
end