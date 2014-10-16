module Concerns
  # Should be used by ActiveFedora models
  # that inherit from other AF models
  # in order to ensure that inheritance
  # relations are modelled correctly.
  module Inheritance
    extend ActiveSupport::Concern
    included do
      def assert_content_model
        super()
        object_superclass = self.class.superclass
        until object_superclass == ActiveFedora::Base || object_superclass == Object
          add_relationship(:has_model, object_superclass.to_class_uri)
          object_superclass = object_superclass.superclass
        end
      end
    end
  end
end
