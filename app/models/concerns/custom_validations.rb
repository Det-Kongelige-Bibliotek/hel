module Concerns
  module CustomValidations
    extend ActiveSupport::Concern
    included do
      def get_validator_from_classname(name)
        classname = "Validator::#{name}"
        klass = Module.const_get(classname)
        if (klass <= ActiveModel::Validator)
          return klass.new
        else
          logger.warn("Validator #{classname} for ContentFile is not a Validator")
          return nil
        end
      rescue NameError => e
        logger.warn("Validator #{classname} for ContentFile not defined")
        logger.warn(e.backtrace.join("\n"))
        return nil?
      end
    end
  end
end