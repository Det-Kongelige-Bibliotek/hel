# This class represents a Work model in
# Fedora. Only KB specific logic should
# live in this class. All domain logic
# e.g. Bibframe, Hydra::Rights etc,
# should live in separate modules and
# be mixed in.
class Work < ActiveFedora::Base
  # include Bibframe::Work
  include Hydra::AccessControls::Permissions
  include Concerns::Renderers
  include Datastreams::TransWalker

  property :language, predicate: ::RDF::Vocab::Bibframe::language, multiple: false
  has_many :titles
  has_many :instances
  has_many :relators
  has_and_belongs_to_many :related_works, class_name: 'Work', predicate: ::RDF::Vocab::Bibframe::relatedWork, inverse_of: :related_works
  has_and_belongs_to_many :preceding_works, class_name: 'Work', predicate: ::RDF::Vocab::Bibframe::precededBy, inverse_of: :succeeding_works
  has_and_belongs_to_many :succeeding_works, class_name: 'Work', predicate: ::RDF::Vocab::Bibframe::succeededBy, inverse_of: :preceding_works
  accepts_nested_attributes_for :titles, :relators

  def uuid
    self.id
  end

  def title_values
    titles.collect(&:value)
  end

  def display_value
    title_values.first
  end

  def to_solr(solr_doc = {})
    solr_doc = super
    Solrizer.insert_field(solr_doc, 'display_value', display_value, :displayable)
    solr_doc
  end

  def add_title(title_hash)
    title_hash.delete(:lang)
    title = Title.new(title_hash)
    self.titles += [title]
  end

  def add_author(agent)
    author_relation = Relator.new(role: 'http://id.loc.gov/vocabulary/relators/aut', agent: agent)
    self.relators += [author_relation]
  end

  def add_recipient(agent)
    recipient_relation = Relator.from_rel('rcp', agent)
    self.relators += [recipient_relation]
  end

  def recipients
    related_agents('rcp')
  end

  def authors
    related_agents('aut')
  end

  # Given a short relator code, find all the related agents
  # with this code
  # e.g. w.related_agents('rcp') will return all recipients
  def related_agents(code)
    recip_rels = self.relators.to_a.select { |rel| rel.short_role == code }
    recip_rels.collect(&:agent)
  end

  def add_related(work)
    logger.warn 'VALHAL DEPRECATION: work.add_related is deprecated - use work.related_works += [work] instead'
    self.related_works += [work]
  end

  def add_preceding(work)
    self.preceding_works += [work]
  end

  def add_succeeding(work)
    self.succeeding_works += [work]
  end



=begin
  has_and_belongs_to_many :instances, class_name: 'Instance', property: :has_instance, inverse_of: :instance_of


  has_and_belongs_to_many :authors, class_name: 'Authority::Agent',  property: :author, inverse_of: :author_of
  has_and_belongs_to_many :recipients, class_name: 'Authority::Agent', property: :recipient, inverse_of: :recipient_of

  belongs_to :is_part_of, class_name: 'Work', property: :is_part_of

  before_save :set_rights_metadata
  validate :has_a_title,:has_a_creator

  # This method i insertet to make cancan authorization work with nested ressources and subclassing
  def trykforlaegs
    instances.where(class: 'Trygforlaeg')
  end

  # In general use these accessors when you want
  # to add a relationship. These will ensure
  # that the relationship is symmetrical and
  # prevent headaches down the line.
  # Note also that these methods will automatically
  # save the object, as AF does this for the related
  # object when creating a relation.
  # DGJ: If inverse_of i set correctly, then we do not need
  # to save the symetrical relation.
  # 'inverse_of' is only a property for has_and_belongs_to_many

  def add_instance(instance)
    work.instances << instance
  end







  def titles=(val)
    remove_titles
    val.each_value do |v|
      add_title(v) unless v['value'].blank?
    end
  end

  def creators
    creators = []
    authors.each do |a|
      creators.push({"id" => a.id, "type"=> 'aut', 'display_value' => a.display_value})
    end
    creators
  end


  def agents
    agents = []
    authors.each do |a|
      agents.push({"id" => a.id, "type"=> 'aut', 'display_value' => a.display_value})
    end
    recipients.each do |rcp|
      agents.push({"id" => rcp.id, "type"=> 'rcp', 'display_value' => rcp.display_value})
    end
    agents
  end

  # this method returns a hash
  # where every author name is a key
  # and the object id is a value
  # e.g. { "Victor Andreasen" => 'valhal:1234' }
  # It can be used to *guess* the value of an author
  # based on a string value, e.g. Victor
  def author_names
    author_names = {}
    authors.each do |aut|
      aut.all_names.each do |name|
        author_names[name] = aut
      end
    end
    author_names
  end

  # Given a name fragment, attempt
  # to find a Person object from the authors
  # that matches this string
  # e.g. given a Work w with author Andreasen, Victor,
  # w.find_matching_author('Victor') will return
  # the Authority::Person object Victor Andreasen
  # If no match is found, return nil
  def find_matching_author(query)
    return nil if query.nil?
    author_names.select do |name, obj|
      next unless name.present?
      return obj if name.include?(query)
    end
    nil
  end

  def creators=(val)
    remove_creators
    val.each_value do |v|
      if (v['type'] == 'aut')
        add_author(ActiveFedora::Base.find(v['id'])) unless v['id'].blank?
      end
    end
  end

  def remove_creators
    authors.each do |aut|
      aut.authored_works.delete self
    end
    authors=[]
  end


  def subjects=(val)
    remove_subjects
    val.each_value do |v|
      add_subject(ActiveFedora::Base.find(v['id'])) unless v['id'].blank?
    end
  end

  def remove_subjects
    subjects=[]
  end


  def to_solr(solr_doc = {})
    super
    Solrizer.insert_field(solr_doc, 'display_value', display_value, :displayable)
    titles.each do |title|
      Solrizer.insert_field(solr_doc, 'title', title.value, :stored_searchable, :displayable)
      Solrizer.insert_field(solr_doc, 'subtitle', title.subtitle, :stored_searchable, :displayable)

    end
    authors.each do |aut|
      Solrizer.insert_field(solr_doc, 'author', aut.all_names,:stored_searchable, :facetable, :displayable)
    end
    self.instances.each do |i|
      Solrizer.insert_field(solr_doc, 'work_activity',i.activity, :facetable)
      Solrizer.insert_field(solr_doc, 'work_collection',i.collection, :facetable)
    end
    solr_doc
  end

  # method to set the rights metadata stream based on activity
  def set_rights_metadata
    self.discover_groups = ['Chronos-Alle']
    self.read_groups = ['Chronos-Alle']
    self.edit_groups = ['Chronos-Alle']
  end

  def display_value
    title_values.first
  end

  # Validation methods
  def has_a_title
    if titles.blank?
      errors.add(:titles,"Et værk skal have mindst en titel")
    end
  end

  def has_a_creator
    if creators.blank?
      errors.add(:creators,"Et værk skal have mindst et ophav")
    end
  end

  # Static methods
  def self.get_title_typeahead_objs
    ActiveFedora::SolrService.query("title_tesim:* && active_fedora_model_ssi:Work",
                                    {:rows => ActiveFedora::SolrService.count("title_tesim:* && active_fedora_model_ssi:Work")})
  end

  # Given an activity name, find all the works
  # that belong to that activity
  # @param activity String
  # @return ['id', 'id']
  def self.find_by_activity(activity)
    docs = ActiveFedora::SolrService.query("work_collection_sim:#{activity} && active_fedora_model_ssi:Work")
    docs.collect { |doc| doc['id'] }
  end
=end
end
