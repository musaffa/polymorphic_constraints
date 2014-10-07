module PolymorphicConstraints
  module Utils
    module PolymorphicErrorHandler
      extend ActiveSupport::Concern

      included do
        rescue_from ActiveRecord::StatementInvalid do |exception|
          if exception.message =~ /Polymorphic record not found./
            raise ActiveRecord::RecordNotFound, exception.message
          elsif exception.message =~ /Polymorphic reference exists./
            raise ActiveRecord::ReferenceViolation, exception.message
          else
            raise exception
          end
        end
      end
    end
  end
end
