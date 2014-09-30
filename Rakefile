begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

require 'pg'
require 'yaml'
require 'sqlite3'
require 'rspec/core/rake_task'
# require 'rdoc/task'
require 'fileutils'

def prepare_database_config(adapter)
  FileUtils.copy "spec/dummy/config/database.#{adapter}.yml", 'spec/dummy/config/database.yml'
end

SQLITE3_FILE_PATH = 'spec/dummy/db/test.sqlite3'

def sqlite3_db
  File.delete(SQLITE3_FILE_PATH) if File.exists?(SQLITE3_FILE_PATH)
  SQLite3::Database.new SQLITE3_FILE_PATH
end

def postgres_db
  path = File.join(File.dirname(__FILE__), 'spec', 'dummy', 'config', 'database.yml')
  yaml = YAML.load_file(path)
  pg_connection_config = yaml['test']
  begin
    conn = PG.connect(dbname: 'postgres',
                      password: pg_connection_config.fetch('password'),
                      host: pg_connection_config.fetch('host'),
                      user: pg_connection_config.fetch('username'))
    conn.exec("DROP DATABASE IF EXISTS #{pg_connection_config['database']};") {}
    conn.exec("CREATE DATABASE #{pg_connection_config['database']};") {}
  rescue PGError => e
    puts e
  ensure
    conn.close unless conn.nil?
  end
end

def connect_db
  path = File.join(File.dirname(__FILE__), 'spec', 'dummy', 'config', 'database.yml')
  yaml = YAML.load_file(path)
  connection_config = yaml['test']

  ActiveRecord::Base.establish_connection(connection_config)
end

def migrate_db
  PolymorphicTables.new.change
end

task :environment, :adapter do |t, args|
  ENV['RAILS_ENV'] ||= 'test'
  prepare_database_config(args.adapter)
  require_relative 'spec/dummy/config/environment'
  require_relative 'spec/dummy/db/migrate/polymorphic_tables'
end

namespace :test do
  namespace :unit do
    task :postgresql do
      RSpec::Core::RakeTask.new(:postgresql) do |t|
        t.pattern = 'spec/lib/polymorphic_constraints/connection_adapters/postgresql_adapter_spec.rb'
      end
      Rake::Task['postgresql'].execute
    end

    task :sqlite do
      RSpec::Core::RakeTask.new(:sqlite) do |t|
        t.pattern = 'spec/lib/polymorphic_constraints/connection_adapters/sqlite3_adapter_spec.rb'
      end
      Rake::Task['sqlite'].execute
    end

    task :all => [:postgresql, :sqlite]
  end

  namespace :integration do
    task :sqlite do
      task(:environment).invoke('sqlite3')

      RSpec::Core::RakeTask.new(:sqlite) do |t|
        t.pattern = 'spec/integration/active_record_integration_spec.rb'
      end

      sqlite3_db
      connect_db
      migrate_db

      Rake::Task['sqlite'].execute
    end

    task :postgresql do
      task(:environment).invoke('postgresql')

      RSpec::Core::RakeTask.new(:postgresql) do |t|
        t.pattern = 'spec/integration/active_record_integration_spec.rb'
      end

      postgres_db
      connect_db
      migrate_db

      Rake::Task['postgresql'].execute
    end
  end
end

# RDoc::Task.new(:rdoc) do |rdoc|
#   rdoc.rdoc_dir = 'rdoc'
#   rdoc.title    = 'PolymorphicConstraints'
#   rdoc.options << '--line-numbers'
#   rdoc.rdoc_files.include('README.rdoc')
#   rdoc.rdoc_files.include('lib/**/*.rb')
# end

# Bundler::GemHelper.install_tasks
