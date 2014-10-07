begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

require 'rspec/core/rake_task'
require 'fileutils'
# require 'rdoc/task'

namespace :test do
  task :prepare_database do
    FileUtils.copy 'spec/dummy/config/database.sqlite.yml', 'spec/dummy/config/database.yml'
  end

  RSpec::Core::RakeTask.new(:unit_specs) do |t|
    t.pattern = ['spec/lib/**/*_spec.rb']
  end

  task :unit => [:prepare_database, :unit_specs]

  namespace :integration do
    rule '.yml' do |file|
      FileUtils.copy ('spec/dummy/config/' + file.name), 'spec/dummy/config/database.yml'
    end

    task :sqlite => 'database.sqlite.yml' do
      RSpec::Core::RakeTask.new(:sqlite_integration) do |t|
        t.pattern = 'spec/integration/active_record_integration_spec.rb'
      end
      Rake::Task['sqlite_integration'].execute
    end
    task :postgresql => 'database.postgresql.yml' do
      RSpec::Core::RakeTask.new(:postgresql_integration) do |t|
        t.pattern = 'spec/integration/active_record_integration_spec.rb'
      end
      Rake::Task['postgresql_integration'].execute
    end
    task :mysql => 'database.mysql.yml' do
      RSpec::Core::RakeTask.new(:mysql_integration) do |t|
        t.pattern = 'spec/integration/active_record_integration_spec.rb'
      end
      Rake::Task['mysql_integration'].execute
    end

    task :all => [:sqlite, :postgresql, :mysql]
  end
end

task :default => ['test:unit', 'test:integration:all']

# RDoc::Task.new(:rdoc) do |rdoc|
#   rdoc.rdoc_dir = 'rdoc'
#   rdoc.title    = 'PolymorphicConstraints'
#   rdoc.options << '--line-numbers'
#   rdoc.rdoc_files.include('README.rdoc')
#   rdoc.rdoc_files.include('lib/**/*.rb')
# end

# Bundler::GemHelper.install_tasks
