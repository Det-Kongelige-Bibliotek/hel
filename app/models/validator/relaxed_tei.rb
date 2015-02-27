module Validator
  class RelaxedTei < Xml
    def initialize
      super
      set_schema(Rails.root.join('config', 'schemas', 'tei_all.rng'))
    end
  end
end