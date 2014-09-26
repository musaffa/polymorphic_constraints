require 'spec_helper'

describe 'Active Record Integration' do

  context 'insertion' do
    it 'raises an exception creating a polymorphic relation without a corresponding record' do
      picture = Picture.new
      picture.imageable_id = 1
      picture.imageable_type = 'Product'
      expect { picture.save }.to raise_error(ActiveRecord::StatementInvalid)
    end

    it 'does not allow an insert of a model type that wasn\'t specified in the polymorphic triggers' do
      product = Product.new
      product.save
      product.reload

      picture = Picture.new
      picture.imageable_id = product.id
      picture.imageable_type = 'World'

      expect { picture.save }.to raise_error(ActiveRecord::StatementInvalid)
    end

    it 'allows an insert of a model type specified in the polymorphic triggers' do
      product = Product.new
      product.save
      product.reload

      picture = Picture.new
      picture.imageable_id = product.id
      picture.imageable_type = product.class.to_s

      expect { picture.save }.to change(Picture, :count).by(1)
    end
  end

  context 'update' do
    it "does not allow an update to a model type that wasn't specified in the polymorphic triggers" do
      product = Product.new
      product.save
      product.reload

      picture = Picture.new
      picture.imageable_id = product.id
      picture.imageable_type = product.class.to_s
      picture.save
      picture.reload

      picture.imageable_type = 'Hello'

      expect { picture.save }.to raise_error(ActiveRecord::StatementInvalid)
    end
  end

  context 'deletion' do
    it 'raises an exception deleting a record that is still referenced by the polymorphic table' do
      product = Product.new
      product.save
      product.reload

      picture = Picture.new
      picture.imageable_id = product.id
      picture.imageable_type = product.class.to_s
      picture.save

      expect { product.delete }.to raise_error(ActiveRecord::StatementInvalid)
      expect { product.destroy }.to raise_error(ActiveRecord::StatementInvalid)
    end

    it 'doesn\'t get in the way of dependent: :destroy' do
      employee = Employee.new
      employee.save
      employee.reload

      picture = Picture.new
      picture.imageable_id = employee.id
      picture.imageable_type = employee.class.to_s
      picture.save

      expect { employee.destroy }.to change(Employee, :count).by(-1)
    end

    it 'does enforce dependency behaviour if delete is used instead of destroy' do
      employee = Employee.new
      employee.save
      employee.reload

      picture = Picture.new
      picture.imageable_id = employee.id
      picture.imageable_type = employee.class.to_s
      picture.save

      expect { employee.delete }.to raise_error(ActiveRecord::StatementInvalid)
    end

    it 'allows a delete of a record NOT referenced by the polymorphic table' do
      employee = Employee.new
      employee.save
      employee.reload

      expect { employee.delete }.to change(Employee, :count).by(-1)
    end

    it 'allows a destroy of a record NOT referenced by the polymorphic table' do
      employee = Employee.new
      employee.save
      employee.reload

      expect { employee.destroy }.to change(Employee, :count).by(-1)
    end
  end
end
