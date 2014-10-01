module PolymorphicConstraints
  module Utils
    module ModelFinder
      def get_polymorphic_models(relation, search_strategy)
        search_strategy == :models_directory ? get_models_from_directory(relation) : get_active_record_descendents(relation)
      end

      private

      def get_models_from_directory(relation)
        models = Dir["#{Rails.root}/app/models/**/*.rb"].map { |f| File.basename(f, '.*').camelize.constantize }
        .select { |klass| klass.ancestors.include?(ActiveRecord::Base) }
        models.select do |klass|
          model_contains_relation?(klass, relation)
        end
      end

      def get_active_record_descendents(relation)
        Rails.application.eager_load!
        ActiveRecord::Base.descendants.select do |klass|
          model_contains_relation?(klass, relation)
        end
      end

      def model_contains_relation?(model_class, relation)
        associations = model_class.reflect_on_all_associations
        associations.map{ |r| r.options[:as] }.include?(relation.to_sym)
      end
    end
  end
end