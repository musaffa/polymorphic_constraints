begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

require 'rspec/core/rake_task'
require 'fileutils'
# require 'rdoc/task'

namespace :test do
  namespace :unit do
    task :prepare_database do
      FileUtils.copy 'spec/dummy/config/database.sqlite.yml', 'spec/dummy/config/database.yml'
    end

    task :sqlite => :prepare_database do
      RSpec::Core::RakeTask.new(:sqlite_adapter) do |t|
        t.pattern = 'spec/lib/polymorphic_constraints/connection_adapters/sqlite3_adapter_spec.rb'
      end
      Rake::Task['sqlite_adapter'].execute
    end

    task :postgresql => :prepare_database do
      RSpec::Core::RakeTask.new(:postgresql_adapter) do |t|
        t.pattern = 'spec/lib/polymorphic_constraints/connection_adapters/postgresql_adapter_spec.rb'
      end
      Rake::Task['postgresql_adapter'].execute
    end

    task :mysql => :prepare_database do
      RSpec::Core::RakeTask.new(:mysql_adapter) do |t|
        t.pattern = 'spec/lib/polymorphic_constraints/connection_adapters/mysql2_adapter_spec.rb'
      end
      Rake::Task['mysql_adapter'].execute
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
    rule '.yml' do |task|
      FileUtils.copy ('spec/' + task.name), 'spec/dummy/config/database.yml'
    end

    task :sqlite => 'dummy/config/database.sqlite.yml' do
      ENV['db_adapter'] = 'sqlite'

      RSpec::Core::RakeTask.new(:sqlite_integration) do |t|
        t.pattern = 'spec/integration/active_record_integration_spec.rb'
      end
      Rake::Task['sqlite_integration'].execute
    end

    task :postgresql => 'dummy/config/database.postgresql.yml' do
      ENV['db_adapter'] = 'postgresql'

      RSpec::Core::RakeTask.new(:postgresql_integration) do |t|
        t.pattern = 'spec/integration/active_record_integration_spec.rb'
      end
      Rake::Task['postgresql_integration'].execute
    end

    task :mysql => 'dummy/config/database.mysql.yml' do
      ENV['db_adapter'] = 'mysql'

      RSpec::Core::RakeTask.new(:mysql_integration) do |t|
        t.pattern = 'spec/integration/active_record_integration_spec.rb'
      end
      Rake::Task['mysql_integration'].execute
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
