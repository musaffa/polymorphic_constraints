class PolymorphicTables < ActiveRecord::Migration
  def change
    create_table :employees do |t|
      t.timestamps null: false
    end

    create_table :products do |t|
      t.timestamps null: false
    end

    create_table :pictures do |t|
      t.references :imageable, polymorphic: true
      t.timestamps null: false
    end

    add_polymorphic_constraints :imageable, :pictures
  end
end