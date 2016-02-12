module Concerns
  # Generic method for working with relators - shared between Work and Instance
  module RelatorMethods
    extend ActiveSupport::Concern
    included do
      # Given a short relator code, find all the related agents
      # with this code
      # e.g. w.related_agents('rcp') will return all recipients
      def related_agents(code)
        recip_rels = self.select_relators(code)
        recip_rels.collect(&:agent)
      end

      # select all relators with this code
      def select_relators(code)
        self.relators.to_a.select { |rel| rel.short_role == code }
      end

      # delete all relators with this code
      def delete_relators(code)
        select_relators(code).each do |rel|
          rel.delete
        end
      end
    end
  end
end