# This class represents a Work model in
# Fedora. Only KB specific logic should
# live in this class. All domain logic
# e.g. Bibframe, Hydra::Rights etc,
# should live in separate modules and
# be mixed in.
class Work < ActiveFedora::Base
  include Bibframe::Work
  include Hydra::AccessControls::Permissions
  include Concerns::UUIDGenerator
  has_many :instances, property: :instance_of
  has_and_belongs_to_many :related_works, class_name: 'Work', property: :related_work, inverse_of: :related_work
  has_and_belongs_to_many :preceding_works, class_name: 'Work', property: :preceded_by, inverse_of: :succeeded_by
  has_and_belongs_to_many :succeeding_works, class_name: 'Work', property: :succeeded_by, inverse_of: :preceded_by
  has_and_belongs_to_many :creators, class_name: 'Authority::Agent', property: :creator, inverse_of: :creator_of
  has_and_belongs_to_many :authors, class_name: 'Authority::Agent', property: :author, inverse_of: :author_of
  has_and_belongs_to_many :recipients, class_name: 'Authority::Agent', property: :recipient, inverse_of: :recipient_of

  # In general use these accessors when you want
  # to add a relationship. These will ensure
  # that the relationship is symmetrical and
  # prevent headaches down the line.
  # Note also that these methods will automatically
  # save the object, as AF does this for the related
  # object when creating a relation.
  def add_related(work)
    work.related_works << self
    related_works << work
  end

  def add_preceding(work)
    work.succeeding_works << self
    preceding_works << work
  end

  def add_succeeding(work)
    work.preceding_works << self
    succeeding_works << work
  end

  def add_creator(agent)
    agent.created_works << self
    creators << agent
  end

  def add_author(agent)
    agent.authored_works << self
    authors << agent
  end

  def add_recipient(agent)
    agent.received_works << self
    recipients << agent
  end

  def to_solr(solr_doc = {})
    super
    title_values.each do |val|
      Solrizer.insert_field(solr_doc, 'title', val, :stored_searchable)
    end
    authors.each do |aut|
      Solrizer.insert_field(solr_doc, 'author', aut.all_names, :facetable)
    end
    creators.each do |cre|
      Solrizer.insert_field(solr_doc, 'creator', cre.all_names, :facetable)
    end
    solr_doc
  end
end
