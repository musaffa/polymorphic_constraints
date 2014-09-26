require 'polymorphic_constraints/connection_adapters/abstract/schema_statements'


module PolymorphicConstraints

end

require 'polymorphic_constraints/migration/command_recorder'
require 'polymorphic_constraints/railtie' if defined?(Rails)
