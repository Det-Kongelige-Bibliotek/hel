module Concerns
  # Generic method for working with relators - shared between Work and Instance
  module RelatorMethods
    extend ActiveSupport::Concern
    included do
      # Given a short relator code, find all the related agents
      # with this code
      # e.g. w.related_agents('rcp') will return all recipients
      def related_agents(code)
        recip_rels = self.relators.to_a.select { |rel| rel.short_role == code }
        recip_rels.collect(&:agent)
      end
    end
  end
end