class Relator < ActiveFedora::Base
  belongs_to :work, predicate: ::RDF::Vocab::Bibframe.relatedTo
  belongs_to :agent, predicate: ::RDF::Vocab::Bibframe.agent, class_name: 'ActiveFedora::Base'
  property :relator_role, predicate: ::RDF::Vocab::Bibframe.relatorRole, multiple: false

  def role
    self.relator_role
  end

  # When the value being set is a rdf:resource,
  # we need to wrap the setter as follows
  def role=(uri)
    self.relator_role = ::RDF::URI.new(uri)
  end
end