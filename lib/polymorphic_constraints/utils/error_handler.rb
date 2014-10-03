module PolymorphicConstraints
  module Utils
    module ErrorHandler
      extend ActiveSupport::Concern

      included do
        rescue_from ActiveRecord::StatementInvalid do |exception|
          if exception.message =~ /Polymorphic Constraints error. Polymorphic record not found./
            raise ActiveRecord::RecordNotFound
          elsif exception.message =~ /Polymorphic Constraints error. Polymorphic reference exists./
            raise ActiveRecord::InvalidForeignKey
          else
            rescue_action_without_handler(exception)
          end
        end
      end
    end
  end
end
