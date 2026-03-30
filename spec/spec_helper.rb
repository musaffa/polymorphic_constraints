require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
end

ENV['RAILS_ENV'] ||= 'test'

require 'dummy/config/environment'
require_relative '../lib/polymorphic_constraints'
require 'rspec/rails'

# Fix Rails 4.2 + Ruby 2.6 compatibility: MonitorMixin#mon_initialize
# raises ThreadError when called twice on the same object, but
# ActionController::TestResponse#recycle! calls initialize again.
# Rails 5.0+ rewrote recycle!, so this is only needed for 4.x.
if Rails::VERSION::MAJOR == 4 && RUBY_VERSION >= '2.6'
  class ActionController::TestResponse < ActionDispatch::TestResponse
    def recycle!
      @mon_mutex = nil
      @mon_mutex_owner_object_id = nil
      @mon_owner = nil
      @mon_count = nil
      initialize
    end
  end
end

ActiveRecord::Migration.verbose = true
Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.after(:all) do
    drop_tables
  end
end

def setup_sqlite3
  cfg = get_connection_config
  ActiveRecord::Base.establish_connection(cfg)
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

def get_connection_config
  if ActiveRecord::Base.respond_to?(:connection_db_config)
    ActiveRecord::Base.connection_db_config.configuration_hash
  else
    ActiveRecord::Base.connection_config
  end
end

def connect_db
  cfg = get_connection_config
  maintenance_db = cfg[:adapter] == 'postgresql' ? 'postgres' : nil
  ActiveRecord::Base.establish_connection(cfg.merge(:database => maintenance_db))
  ActiveRecord::Base.connection.recreate_database(cfg[:database])
  ActiveRecord::Base.establish_connection(cfg)
end

def migrate_db
  path = File.join(Rails.root, 'db/migrate')
  if !defined?(ActiveRecord::MigrationContext)
    ActiveRecord::Migrator.migrate(path)
  elsif ActiveRecord::MigrationContext.instance_method(:initialize).parameters.count { |type, _| type == :req } > 1
    ActiveRecord::MigrationContext.new(path, ActiveRecord::SchemaMigration).migrate
  else
    ActiveRecord::MigrationContext.new(path).migrate
  end
end

def drop_tables
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end
