class Relator < ActiveFedora::Base
  belongs_to :work, predicate: ::RDF::Vocab::Bibframe.relatedTo
  belongs_to :agent, predicate: ::RDF::Vocab::Bibframe.agent, class_name: 'ActiveFedora::Base'
  property :relator_role, predicate: ::RDF::Vocab::Bibframe.relatorRole, multiple: false

  validates :work, :agent, :relator_role, presence: true

  # we show the uri
  def role
    self.relator_role.to_term.value
  end

  # When the value being set is a rdf:resource,
  # we need to wrap the setter as follows
  def role=(uri)
    self.relator_role = ::RDF::URI.new(uri)
  end

  def agent_id=(id)
    self.agent = ActiveFedora::Base.find(id)
  end

  def agent_id
    self.agent.try(:id)
  end
end