ENV['RAILS_ENV'] ||= 'test'

require 'dummy/config/environment'
require_relative '../lib/polymorphic_constraints'
require 'rspec/rails'

ActiveRecord::Migration.verbose = true
Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.after(:all) do
    drop_tables
  end
end

def setup_sqlite
  connection_config = ActiveRecord::Base.connection_config
  ActiveRecord::Base.establish_connection(connection_config)
  migrate_db
end

def setup_postgresql
  connection_config = ActiveRecord::Base.connection_config
  ActiveRecord::Base.establish_connection(connection_config.merge(:database => nil))
  ActiveRecord::Base.connection.recreate_database(connection_config[:database])
  ActiveRecord::Base.establish_connection(connection_config)
  migrate_db
end

def setup_mysql
  connection_config = ActiveRecord::Base.connection_config
  ActiveRecord::Base.establish_connection(connection_config.merge(:database => nil))
  ActiveRecord::Base.connection.recreate_database(connection_config[:database])
  ActiveRecord::Base.establish_connection(connection_config)
  migrate_db
end

private

def migrate_db
  ActiveRecord::Migrator.migrate(File.join(Rails.root, 'db/migrate'))
end

def drop_tables
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end
