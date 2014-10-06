begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

require 'rspec/core/rake_task'
require 'fileutils'
# require 'rdoc/task'

def prepare_database_config(db_adapter)
  FileUtils.copy "spec/dummy/config/database.#{db_adapter}.yml", 'spec/dummy/config/database.yml'
end

namespace :test do
  namespace :unit do
    task :prepare_database do
      prepare_database_config('sqlite')
    end

    task :sqlite => :prepare_database do
      RSpec::Core::RakeTask.new(:sqlite) do |t|
        t.pattern = 'spec/lib/polymorphic_constraints/connection_adapters/sqlite3_adapter_spec.rb'
      end
      Rake::Task['sqlite'].execute
    end

    task :postgresql => :prepare_database do
      RSpec::Core::RakeTask.new(:postgresql) do |t|
        t.pattern = 'spec/lib/polymorphic_constraints/connection_adapters/postgresql_adapter_spec.rb'
      end
      Rake::Task['postgresql'].execute
    end

    task :mysql => :prepare_database do
      RSpec::Core::RakeTask.new(:mysql) do |t|
        t.pattern = 'spec/lib/polymorphic_constraints/connection_adapters/mysql2_adapter_spec.rb'
      end
      Rake::Task['mysql'].execute
    end

    task :error_handler => :prepare_database do
      RSpec::Core::RakeTask.new(:error_handler) do |t|
        t.pattern = 'spec/lib/polymorphic_constraints/utils/polymorphic_error_handler_spec.rb'
      end
      Rake::Task['error_handler'].execute
    end

    task :all => [:sqlite, :postgresql, :mysql, :error_handler]
  end

  namespace :integration do
    task :sqlite do
      ENV['db_adapter'] = 'sqlite'
      prepare_database_config('sqlite')

      RSpec::Core::RakeTask.new(:sqlite) do |t|
        t.pattern = 'spec/integration/active_record_integration_spec.rb'
      end
      Rake::Task['sqlite'].execute
    end

    task :postgresql do
      ENV['db_adapter'] = 'postgresql'
      prepare_database_config('postgresql')

      RSpec::Core::RakeTask.new(:postgresql) do |t|
        t.pattern = 'spec/integration/active_record_integration_spec.rb'
      end
      Rake::Task['postgresql'].execute
    end

    task :mysql do
      ENV['db_adapter'] = 'mysql'
      prepare_database_config('mysql')

      RSpec::Core::RakeTask.new(:mysql) do |t|
        t.pattern = 'spec/integration/active_record_integration_spec.rb'
      end
      Rake::Task['mysql'].execute
    end

    task :all => [:sqlite, :postgresql, :mysql]
  end
end

task :default => ['test:unit:all', 'test:integration:all']

# RDoc::Task.new(:rdoc) do |rdoc|
#   rdoc.rdoc_dir = 'rdoc'
#   rdoc.title    = 'PolymorphicConstraints'
#   rdoc.options << '--line-numbers'
#   rdoc.rdoc_files.include('README.rdoc')
#   rdoc.rdoc_files.include('lib/**/*.rb')
# end

# Bundler::GemHelper.install_tasks
