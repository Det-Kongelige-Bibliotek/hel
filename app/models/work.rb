# -*- coding: utf-8 -*-
# This class represents a Work model in
# Fedora. Only KB specific logic should
# live in this class. All domain logic
# e.g. Bibframe, Hydra::Rights etc,
# should live in separate modules and
# be mixed in.
class Work < ActiveFedora::Base
  include Hydra::AccessControls::Permissions
  include Concerns::RelatorMethods
  include Datastreams::TransWalker

  property :language, predicate: ::RDF::Vocab::Bibframe::language, multiple: false
  property :origin_date, predicate: ::RDF::Vocab::Bibframe::originDate, multiple: false
  belongs_to :origin_place, predicate: ::RDF::Vocab::Bibframe::originPlace, class_name: 'Authority::Place'
  has_many :titles
  has_many :instances
  has_many :relators, predicate: ::RDF::Vocab::Bibframe.relatedTo
  has_and_belongs_to_many :related_works, class_name: 'Work', predicate: ::RDF::Vocab::Bibframe::relatedWork, inverse_of: :related_works
  has_and_belongs_to_many :preceding_works, class_name: 'Work', predicate: ::RDF::Vocab::Bibframe::precededBy, inverse_of: :succeeding_works
  has_and_belongs_to_many :succeeding_works, class_name: 'Work', predicate: ::RDF::Vocab::Bibframe::succeededBy, inverse_of: :preceding_works
  has_and_belongs_to_many :parts, class_name: 'Work', predicate: ::RDF::Vocab::Bibframe::hasPart, inverse_of: :is_part_of
  belongs_to :is_part_of, class_name: 'Work', predicate: ::RDF::Vocab::Bibframe::partOf
  accepts_nested_attributes_for :titles, :allow_destroy => true
  accepts_nested_attributes_for :relators, :allow_destroy => true, reject_if: proc { |attrs| attrs['agent_id'].blank? }

  validate :has_a_title,:has_a_creator

  before_save :set_rights_metadata

  after_save :disseminate_all_instances

  validates_each :origin_date do |record, attr, val|
    record.errors.add(attr, I18n.t('edtf.error_message')) if val.present? && EDTF.parse(val).nil?
  end

  def disseminate_all_instances
    self.instances.each do |i|
      Resque.enqueue(DisseminateJob,i.id) unless i.cannot_be_published?
    end
  end

  # Validation methods
  def has_a_title
    unless titles.size > 0
      errors.add(:titles,"Et værk skal have mindst en titel")
      #fail("Et værk skal have mindst en titel")
    end
  end

  # TODO: this should check all creative relation types
  # we need therefore a subset of relators which are *creative*
  def has_a_creator
    if creative_roles.size == 0
      errors.add(:creator,"et værk skal have mindst et ophav")
    end
  end

  def uuid
    self.id
  end

  def title_values
    titles.collect(&:value)
  end

  def display_value
    title_values.first
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

  def creators
    related_agents('cre')
  end

  def editors
    related_agents('edt')
  end

  def creative_roles
    authors + creators
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

  # this method returns a hash
  # where every author name is a key
  # and the object id is a value
  # e.g. { "Victor Andreasen" => 'valhal:1234' }
  # It can be used to *guess* the value of an author
  # based on a string value, e.g. Victor
  def author_names
    author_names = {}
    authors.each do |aut|
      author_names[aut.full_name] = aut
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

  def to_solr(solr_doc = {})
    solr_doc.merge!(super)
    Solrizer.insert_field(solr_doc, 'display_value', display_value, :displayable)
    titles.each do |title|
      Solrizer.insert_field(solr_doc, 'title', title.value, :stored_searchable, :displayable)
      Solrizer.insert_field(solr_doc, 'subtitle', title.subtitle, :stored_searchable, :displayable)
    end
    authors.each do |aut|
      Solrizer.insert_field(solr_doc, 'author', aut.display_value,:stored_searchable, :facetable, :displayable) unless aut.nil?
    end
    instances.each do |i|
      Solrizer.insert_field(solr_doc, 'work_activity', i.activity, :facetable)
      Solrizer.insert_field(solr_doc, 'work_collection', i.collection, :facetable)
      Solrizer.insert_field(solr_doc, 'instances', i.id, :displayable)
    end
    solr_doc
  end

  # method to set the rights metadata stream based on activity
  def set_rights_metadata
    self.discover_groups = ['Chronos-Alle']
    self.read_groups = ['Chronos-Alle']
    self.edit_groups = ['Chronos-Alle']
  end

  def add_instance(i)
    self.instances.push(i)
  end



end

=begin
  has_and_belongs_to_many :instances, class_name: 'Instance', property: :has_instance, inverse_of: :instance_of
  has_and_belongs_to_many :related_works, class_name: 'Work', property: :related_work, inverse_of: :related_work
  has_and_belongs_to_many :preceding_works, class_name: 'Work', property: :preceded_by, inverse_of: :succeeded_by
  has_and_belongs_to_many :succeeding_works, class_name: 'Work', property: :succeeded_by, inverse_of: :preceded_by
  has_and_belongs_to_many :authors, class_name: 'Authority::Agent',  property: :author, inverse_of: :author_of
  has_and_belongs_to_many :recipients, class_name: 'Authority::Agent', property: :recipient, inverse_of: :recipient_of
  has_and_belongs_to_many :subjects, class_name: 'ActiveFedora::Base', property: :subject

  before_save :set_rights_metadata
  validate :has_a_title,:has_a_creator


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
=end
