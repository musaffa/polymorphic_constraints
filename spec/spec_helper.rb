ENV['RAILS_ENV'] ||= 'test'

require_relative 'dummy/config/environment'
require 'rspec/rails'
require 'pg'
require_relative 'dummy/db/migrate/1_test_records'
require_relative '../lib/polymorphic_constraints'

# ActiveRecord::Migration.maintain_test_schema!
ActiveRecord::Migration.verbose = false

RSpec.configure do |config|
  # config.use_transactional_fixtures = true
  config.before(:all) do
    create_db
    connect_db
    migrate_db
  end

  config.after(:all) do
    drop_tables
  end
end

def create_db
  postgres_db
end

def postgres_db
  path = File.join(File.dirname(__FILE__), 'dummy', 'config', 'database.yml')
  yaml = YAML.load_file(path)
  pg_connection_config = yaml['test']
  begin
    conn = PG.connect(dbname: 'postgres',
                      password: pg_connection_config.fetch("password"),
                      host: pg_connection_config.fetch("host"),
                      user: pg_connection_config.fetch("username"))
    conn.exec("DROP DATABASE IF EXISTS #{pg_connection_config['database']};") {}
    conn.exec("CREATE DATABASE
      #{pg_connection_config['database']};") {}
  rescue PGError => e
    puts e
  ensure
    conn.close unless conn.nil?
  end
end

def connect_db
  path = File.join(File.dirname(__FILE__), 'dummy', 'config', 'database.yml')
  yaml = YAML.load_file(path)
  connection_config = yaml['test']

  ActiveRecord::Base.establish_connection(connection_config)
end

def migrate_db
  TestRecords.new.change
end

def drop_tables
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end
