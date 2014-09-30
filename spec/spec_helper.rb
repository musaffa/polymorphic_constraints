ENV['RAILS_ENV'] ||= 'test'

require 'dummy/config/environment'
require_relative '../lib/polymorphic_constraints'
require 'rspec/rails'

# ActiveRecord::Migration.maintain_test_schema!
ActiveRecord::Migration.verbose = true
Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each { |f| require f }

RSpec.configure do |config|
  # config.use_transactional_fixtures = true
  config.after(:all) do
    drop_tables
  end
end

def drop_tables
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end
