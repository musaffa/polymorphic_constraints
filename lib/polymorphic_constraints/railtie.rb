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

      ActiveSupport.on_load :action_controller do
        require 'polymorphic_constraints/utils/polymorphic_error_handler'
        include PolymorphicConstraints::Utils::PolymorphicErrorHandler
      end
    end
  end
end