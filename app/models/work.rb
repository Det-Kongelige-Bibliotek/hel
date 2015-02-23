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
  include Concerns::Renderers
  include Datastreams::TransWalker

  has_and_belongs_to_many :instances, class_name: 'Instance', property: :has_instance, inverse_of: :instance_of
  has_and_belongs_to_many :related_works, class_name: 'Work', property: :related_work, inverse_of: :related_work
  has_and_belongs_to_many :preceding_works, class_name: 'Work', property: :preceded_by, inverse_of: :succeeded_by
  has_and_belongs_to_many :succeeding_works, class_name: 'Work', property: :succeeded_by, inverse_of: :preceded_by
  has_and_belongs_to_many :authors, class_name: 'Authority::Agent',  property: :author, inverse_of: :author_of
  has_and_belongs_to_many :recipients, class_name: 'Authority::Agent', property: :recipient, inverse_of: :recipient_of
  has_and_belongs_to_many :subjects, class_name: 'Authority::Base', property: :subject, inverse_of: :subject_of

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

  def add_related(work)
    related_works << work
  end

  def add_preceding(work)
    preceding_works << work
  end

  def add_succeeding(work)
    succeeding_works << work
  end

  def add_author(agent)
    authors << agent
  end

  def add_recipient(agent)
    recipients << agent
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

  def creators=(val)
    remove_creators
    val.each_value do |v|
      logger.debug("adding creator #{v}")
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

  def add_subject(agent)
    subjects << agent
  end

  def subjects=(val)
    logger.debug("subjects are #{val.inspect}")
    remove_subjects
    val.each_value do |v|
      logger.debug("adding subject #{v}")
      add_subject(ActiveFedora::Base.find(v['id'])) unless v['id'].blank?
    end
  end

  def remove_subjects
    subjects.each do |s|
      s.subject_of.delete self
    end
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
end
