# Polymorphic Constraints

[![Build Status](https://travis-ci.org/musaffa/polymorphic_constraints.svg)](https://travis-ci.org/musaffa/polymorphic_constraints)

Polymorphic Constraints gem introduces some methods to your migrations to help to maintain the referential integrity for your Rails polymorphic associations.

It uses triggers to enforce the constraints. It enforces constraints on `insert`, `update` and `delete`. `update` and `delete` constraints works like the `:restrict` option of foreign key. 

It supports the following adapters:

* sqlite3
* postgresql
* mysql2

## Installation

Add the following to your Gemfile:

```ruby
gem 'polymorphic_constraints'
```
## API Examples

This gem adds the following methods to your migrations:

* add_polymorphic_constraints(relation, associated_model, options)
* update_polymorphic_constraints(relation, associated_model, options)
* remove_polymorphic_constraints(relation)

From [Rails Guide](http://guides.rubyonrails.org/association_basics.html#polymorphic-associations)
take these examples:

```ruby
class Picture < ActiveRecord::Base
  belongs_to :imageable, polymorphic: true
end
 
class Employee < ActiveRecord::Base
  has_many :pictures, as: :imageable, dependent: :destroy
end
 
class Product < ActiveRecord::Base
  has_many :pictures, as: :imageable
end
```

Add a new migration:

```ruby
class AddPolymorphicConstraints < ActiveRecord::Migration
  def change
    add_polymorphic_constraints :imageable, :pictures
  end
end
```
Or you can add it to pictures migration:

```ruby
class CreateComments < ActiveRecord::Migration
  create_table :pictures do |t|
    t.references :imageable, polymorphic: true
    t.timestamps
  end

  add_polymorphic_constraints :imageable, :pictures
end
```

For the second method to work properly, the polymorphic tables `employees` and `products` have to be in the database first i.e `pictures` migration should come after the migrations of `employees` and `products`.

run: `rake db:migrate`

This migration will create the necessary triggers to apply insert, update and delete constraints on polymorphic relation named `imageable`.

```ruby
# insert
>> picture = Picture.new
>> picture.imageable_id = 1
>> picture.imageable_type = 'Product'
>> picture.save # raises ActiveRecord::RecordNotFound exception. there's no product with id 1

>> product = Product.create

>> picture.imageable_id = product.id
>> picture.imageable_type = 'World'
>> picture.save # raises ActiveRecord::RecordNotFound exception. there's no imageable model named 'World'.

>> picture.imageable_type = product.class.to_s # 'Product'
>> picture.save # saves successfully

# update
>> picture.imageable_type = 'Hello'
>> picture.save # raises ActiveRecord::RecordNotFound exception. there's no imageable model named 'Hello'.

>> employee = Employee.create

>> picture.imageable_id = employee.id
>> picture.imageable_type = employee.class.to_s # 'Employee'
>> picture.save # update completes successfully

# delete/destroy
>> employee.delete # raises ActiveRecord::InvalidForeignKey exeption. cannot delete because the picture still refers to the employee as the imageable.
>> employee.destroy # destroys successfully. unlike product, employee implements dependent destroy on imageable. so it destroys the picture first, then it destroys itself.
>> Employee.count # 0
>> Picture.count # 0

>> picture = Picture.new
>> picture.imageable_id = product.id
>> picture.imageable_type = product.class.to_s # 'Product'
>> picture.save

>> product.delete # raises ActiveRecord::InvalidForeignKey exeption. cannot delete because the picture still refers to the product as the imageable.
>> product.destroy # raises ActiveRecord::InvalidForeignKey exeption. works the same as delete because product model hasn't implemented dependent destroy on imageable.

>> another_product = Product.create
>> another_product.delete # deletes successfully as no picture refers to this product.
```

## Model Search Strategy:

When you add polymorphic constraints like this:

```ruby
add_polymorphic_constraints :imageable, :pictures
```

the gem will search for models acting as imageable using `ActiveRecord::Base.descendants`. This will search all the models including your gems, models directory etc.

Or if you want to search only standard app/models, then you can use `:models_directory` as the search strategy:
```ruby
add_polymorphic_constraints :imageable, :pictures, search_strategy: :models_directory
```
This will search only the models in the standard models directory.

**Note:** `:models_directory` search strategy assumes all the model classes are named after their file names.

You can also explicitly specify the models with which you want to create polymorphic constraints.
```ruby
add_polymorphic_constraints :imageable, :pictures, polymorphic_models: [:employee]
```
This will create polymorphic constraints only between `pictures` and `employees`. `:polymorphic_models` will supersede `:search_strategy`.

**Note:** the polymorphic_models option is an array. The models specified in the array should be in singular form. Make sure the models indeed have the polymorphic relationship (in this example, `:employee` acting as `:imageable` with `:pictures`).

## Update Constraints

This gem creates triggers using the existing state of the application. If you add any model later or add new polymorphic relationships in the existing model, it wont have any polymorphic constraint applied to it. For example, if you add a member class later in the application life cycle:
```ruby
class Member < ActiveRecord::Base
  has_many :pictures, as: :imageable, dependent: :destroy
end
```
There will be no polymorphic constraints between `pictures` and `members`. You have to renew the `imageable` constraints by adding another migration:

```ruby
class AgainUpdatePolymorphicConstraints < ActiveRecord::Migration
  def change
    update_polymorphic_constraints :imageable, :pictures
  end
end
```
This will delete all the existing `:imageable` constraints and create new ones. You can also specify `:search_strategy` and `:polymorphic_models` options with `update_polymorphic_constraints` method. See [Model Search Strategy](#model-search-strategy)

**Note:** `update_polymorphic_constraints` is simply an alias to `add_polymorphic_constraints`.

## Schema Dump

The gem doesn't support `ruby` schema dump yet. You have to dump `sql` instead of schema.rb. To do this, change the application config settings:

```ruby
# app/config/application.rb
config.active_record.schema_format = :sql
```

```ruby
rake db:structure:dump
```

## Migration Rollback

`add_polymorphic_constraints` and `update_polymorphic_constraints` are both reversible. So you don't need to worry about rollback.

```ruby
class AddPolymorphicConstraints < ActiveRecord::Migration
  def change
    add_polymorphic_constraints :imageable, :pictures
  end
end
```

If you can also use `up` and `down` like this:

```ruby
class AddPolymorphicConstraints < ActiveRecord::Migration
  def self.up
    add_polymorphic_constraints :imageable, :pictures
  end

  def self.down
    remove_polymorphic_constraints :imageable
  end
end
```

This `remove_polymorphic_constraints` will delete all the existing `:imageable` constraints during rollback.

**Caution:** After migration, always test if rollback works properly.

## Tests

```ruby
rake test:unit:all
rake test:integration:sqlite
rake test:integration:postgresql
rake test:integration:mysql
```

## Problems

Please use GitHub's [issue tracker](http://github.com/musaffa/polymorphic_constraints/issues).

## TODO
1. Ruby schema dump
2. Supporting `on_delete`, `on_update` options with `:nullify`, `:restrict` and `:cascade`.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Inspirations

* [Foreigner](https://github.com/matthuhiggins/foreigner)
* [Fides](https://github.com/mkraft/fides)

## License

This project rocks and uses MIT-LICENSE.