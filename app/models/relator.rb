class Relator < ActiveFedora::Base
  belongs_to :work, predicate: ::RDF::Vocab::Bibframe::relatedTo
  belongs_to :instance, predicate: ::RDF::Vocab::Bibframe::relatedTo
  belongs_to :agent, predicate: ::RDF::Vocab::Bibframe.agent, class_name: 'ActiveFedora::Base'
  property :relator_role, predicate: ::RDF::Vocab::Bibframe.relatorRole, multiple: false

  validates :agent, presence: true
  validate :work_or_instance_present

  # we show the uri
  def role
    self.relator_role.to_term.value unless self.relator_role.nil?
  end

  # When the value being set is a rdf:resource,
  # we need to wrap the setter as follows
  def role=(uri)
    self.relator_role = ::RDF::URI.new(uri)
  end

  # retrieve the last part of a role URI
  # e.g. given a Relator r with role
  # http://id.loc.gov/vocabulary/relators/rcp
  # r.short_role => 'rcp'
  def short_role
    URI(role).path.split('/').last
  end

  def agent_id=(id)
    self.agent = ActiveFedora::Base.find(id) if id.present?
  end

  def agent_id
    self.agent.try(:id)
  end

  def self.from_rel(rel, agent)
    uri = "http://id.loc.gov/vocabulary/relators/#{rel}"
    self.new(role: uri, agent: agent)
  end

  private

  # we should have a work or an instance but not both
  def work_or_instance_present
    unless work.blank? ^ instance.blank?
      errors.add(:base, 'En Relator skal enten have tilknyttet enten et Værk eller en Instans')
    end
  end
end
