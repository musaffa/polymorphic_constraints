module PolymorphicConstraints
  module Migration
    module CommandRecorder
      def add_polymorphic_constraints(*args)
        record(:add_polymorphic_constraints, args)
      end

      def remove_polymorphic_constraints(*args)
        record(:remove_polymorphic_constraints, args)
      end

      def invert_add_polymorphic_constraints(args)
        relation, associated_model, opts = *args
        [:remove_polymorphic_constraints, relation]
      end
    end
  end
end