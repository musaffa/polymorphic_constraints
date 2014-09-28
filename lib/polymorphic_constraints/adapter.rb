module PolymorphicConstraints
  class Adapter
    class_attribute :registered
    self.registered = {}

    class << self
      def register(adapter_name, file_name)
        registered[adapter_name] = file_name
      end

      def load!
        if registered.key?(configured_name)
          require registered[configured_name]
        else
          p "Database adapter #{configured_name} not supported. Use:\n" +
                "PolymorphicConstraints::Adapter.register '#{configured_name}', 'path/to/adapter'"
        end
      end

      def configured_name
        @configured_name ||= ActiveRecord::Base.connection_pool.spec.config[:adapter]
      end

      def safe_include(adapter_class_name, adapter_ext)
        ActiveRecord::ConnectionAdapters.const_get(adapter_class_name).class_eval do
          unless ancestors.include? adapter_ext
            include adapter_ext
          end
        end
      rescue
      end
    end
  end
end