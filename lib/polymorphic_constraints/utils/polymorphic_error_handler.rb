module PolymorphicConstraints
  module Utils
    module PolymorphicErrorHandler
      extend ActiveSupport::Concern

      included do
        rescue_from ActiveRecord::StatementInvalid do |exception|
          if exception.message =~ /Polymorphic Constraints error. Polymorphic record not found./
            raise ActiveRecord::RecordNotFound, exception.message
          elsif exception.message =~ /Polymorphic Constraints error. Polymorphic reference exists./
            raise ActiveRecord::InvalidForeignKey, exception.message
          else
            raise exception
          end
        end
      end
    end
  end
end
