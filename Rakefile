begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

require 'sqlite3'
require 'pg'
require 'mysql2'
require 'yaml'
require 'fileutils'
require 'rspec/core/rake_task'
# require 'rdoc/task'

def prepare_database_config(adapter)
  FileUtils.copy "spec/dummy/config/database.#{adapter}.yml", 'spec/dummy/config/database.yml'
end

def connection_config
  path = File.join(File.dirname(__FILE__), 'spec', 'dummy', 'config', 'database.yml')
  yaml = YAML.load_file(path)
  yaml['test']
end

SQLITE3_FILE_PATH = 'spec/dummy/db/test.sqlite3'

def sqlite3_db
  prepare_database_config('sqlite')
  File.delete(SQLITE3_FILE_PATH) if File.exists?(SQLITE3_FILE_PATH)
  SQLite3::Database.new SQLITE3_FILE_PATH
end

def postgres_db
  prepare_database_config('postgresql')
  pg_connection_config = connection_config

  begin
    client = PG.connect(user: pg_connection_config.fetch('username'),
                        host: pg_connection_config.fetch('host'))
    client.exec("DROP DATABASE IF EXISTS #{pg_connection_config['database']};") {}
    client.exec("CREATE DATABASE #{pg_connection_config['database']};") {}
  rescue PGError => e
    puts e
  ensure
    client.close unless client.nil?
  end
end

def mysql_db
  prepare_database_config('mysql')
  mysql_connection_config = connection_config

  begin
    client = Mysql2::Client.new(username: mysql_connection_config.fetch('username'),
                                host: mysql_connection_config.fetch('host'))
    client.query("DROP DATABASE IF EXISTS #{mysql_connection_config['database']};")
    client.query("CREATE DATABASE #{mysql_connection_config['database']};")
  rescue Mysql2::Error => e
    puts e
  ensure
    client.close unless client.nil?
  end
end

def connect_db
  ActiveRecord::Base.establish_connection(connection_config)
end

def migrate_db
  PolymorphicTables.new.change
  UpdateConstraints.new.change
end


namespace :test do
  ENV['RAILS_ENV'] ||= 'test'

  namespace :unit do
    task :sqlite do
      RSpec::Core::RakeTask.new(:sqlite) do |t|
        t.pattern = 'spec/lib/polymorphic_constraints/connection_adapters/sqlite3_adapter_spec.rb'
      end
      Rake::Task['sqlite'].execute
    end

    task :postgresql do
      RSpec::Core::RakeTask.new(:postgresql) do |t|
        t.pattern = 'spec/lib/polymorphic_constraints/connection_adapters/postgresql_adapter_spec.rb'
      end
      Rake::Task['postgresql'].execute
    end

    task :mysql do
      RSpec::Core::RakeTask.new(:mysql) do |t|
        t.pattern = 'spec/lib/polymorphic_constraints/connection_adapters/mysql2_adapter_spec.rb'
      end
      Rake::Task['mysql'].execute
    end

    task :error_handler do
      RSpec::Core::RakeTask.new(:error_handler) do |t|
        t.pattern = 'spec/lib/polymorphic_constraints/utils/polymorphic_error_handler_spec.rb'
      end
      Rake::Task['error_handler'].execute
    end

    task :all => [:sqlite, :postgresql, :mysql, :error_handler]
  end

  namespace :integration do
    require_relative 'spec/dummy/config/environment'
    require_relative 'spec/dummy/db/migrate/20141002195532_polymorphic_tables'
    require_relative 'spec/dummy/db/migrate/20141005192259_update_constraints'

    task :sqlite do
      RSpec::Core::RakeTask.new(:sqlite) do |t|
        t.pattern = 'spec/integration/active_record_integration_spec.rb'
      end

      sqlite3_db
      connect_db
      migrate_db

      Rake::Task['sqlite'].execute
    end

    task :postgresql do
      RSpec::Core::RakeTask.new(:postgresql) do |t|
        t.pattern = 'spec/integration/active_record_integration_spec.rb'
      end

      postgres_db
      connect_db
      migrate_db

      Rake::Task['postgresql'].execute
    end

    task :mysql do
      RSpec::Core::RakeTask.new(:mysql) do |t|
        t.pattern = 'spec/integration/active_record_integration_spec.rb'
      end

      mysql_db
      connect_db
      migrate_db

      Rake::Task['mysql'].execute
    end
  end
end

task :default => 'test:unit:all'

# RDoc::Task.new(:rdoc) do |rdoc|
#   rdoc.rdoc_dir = 'rdoc'
#   rdoc.title    = 'PolymorphicConstraints'
#   rdoc.options << '--line-numbers'
#   rdoc.rdoc_files.include('README.rdoc')
#   rdoc.rdoc_files.include('lib/**/*.rb')
# end

# Bundler::GemHelper.install_tasks
