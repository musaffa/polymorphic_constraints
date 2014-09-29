require 'active_support/all'


module PolymorphicConstraints
  extend ActiveSupport::Autoload
  autoload :Adapter

  module ConnectionAdapters
    extend ActiveSupport::Autoload

    autoload_under 'abstract' do
      autoload :SchemaDefinitions
      autoload :SchemaStatements
      autoload :Table
    end
  end

  module Migration
    autoload :CommandRecorder, 'polymorphic_constraints/migration/command_recorder'
  end
end

PolymorphicConstraints::Adapter.register 'postgresql', 'polymorphic_constraints/connection_adapters/postgresql_adapter'
PolymorphicConstraints::Adapter.register 'sqlite3', 'polymorphic_constraints/connection_adapters/sqlite3_adapter'

require 'polymorphic_constraints/railtie' if defined?(Rails)
