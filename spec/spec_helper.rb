ENV['RAILS_ENV'] ||= 'test'

require 'dummy/config/environment'
require_relative '../lib/polymorphic_constraints'
require 'rspec/rails'
require 'coveralls'

Coveralls.wear!

ActiveRecord::Migration.verbose = true
Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.after(:all) do
    drop_tables
  end
end

def setup_sqlite3
  connection_config = ActiveRecord::Base.connection_config
  ActiveRecord::Base.establish_connection(connection_config)
  migrate_db
end

def setup_postgresql
  connect_db
  migrate_db
end

def setup_mysql2
  connect_db
  migrate_db
end

private

def connect_db
  connection_config = ActiveRecord::Base.connection_config
  ActiveRecord::Base.establish_connection(connection_config.merge(:database => nil))
  ActiveRecord::Base.connection.recreate_database(connection_config[:database])
  ActiveRecord::Base.establish_connection(connection_config)
end

def migrate_db
  ActiveRecord::Migrator.migrate(File.join(Rails.root, 'db/migrate'))
end

def drop_tables
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end
