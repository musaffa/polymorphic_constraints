module PolymorphicConstraints
  class Railtie < Rails::Railtie
    initializer 'polymorphic_constraints.load_migration' do
      ActiveSupport.on_load :active_record do
        ActiveRecord::ConnectionAdapters.module_eval do
          include PolymorphicConstraints::ConnectionAdapters::SchemaStatements
          include PolymorphicConstraints::ConnectionAdapters::SchemaDefinitions
        end

        if defined?(ActiveRecord::Migration::CommandRecorder)
          ActiveRecord::Migration::CommandRecorder.class_eval do
            include PolymorphicConstraints::Migration::CommandRecorder
          end
        end

        PolymorphicConstraints::Adapter.load!
      end
    end
  end
end