module PolymorphicConstraints
  module Utils
    module PolymorphicModelFinder
      def get_polymorphic_models(relation)
        Rails.application.eager_load!
        ActiveRecord::Base.descendants.select do |klass|
          contains_polymorphic_relation?(klass, relation)
        end
      end

      private

      def contains_polymorphic_relation?(model_class, relation)
        associations = model_class.reflect_on_all_associations
        associations.map{ |r| r.options[:as] }.include?(relation.to_sym)
      end
    end
  end
end