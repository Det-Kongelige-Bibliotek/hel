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
  include Concerns::RDFOutput

  has_and_belongs_to_many :instances, property: :has_instance, inverse_of: :instance_of
  has_and_belongs_to_many :related_works, class_name: 'Work', property: :related_work, inverse_of: :related_work
  has_and_belongs_to_many :preceding_works, class_name: 'Work', property: :preceded_by, inverse_of: :succeeded_by
  has_and_belongs_to_many :succeeding_works, class_name: 'Work', property: :succeeded_by, inverse_of: :preceded_by
  has_and_belongs_to_many :authors, class_name: 'Authority::Agent',  property: :author, inverse_of: :author_of
  has_and_belongs_to_many :recipients, class_name: 'Authority::Agent', property: :recipient, inverse_of: :recipient_of

  # In general use these accessors when you want
  # to add a relationship. These will ensure
  # that the relationship is symmetrical and
  # prevent headaches down the line.
  # Note also that these methods will automatically
  # save the object, as AF does this for the related
  # object when creating a relation.
  def add_instance(instance)
    instance.work = self
    work.instances << instance
  end

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

  def add_author(agent)
    agent.authored_works << self
    authors << agent
  end

  def add_recipient(agent)
    agent.received_works << self
    recipients << agent
  end

  def titles=(val)
    remove_titles
    val.each_value do |v|
      logger.debug("adding titel #{v}")
      add_title(v) unless v['value'].blank? && v['subtitle'].blank?
    end
  end

  def creators
    creators = []
    authors.each do |a|
      creators.push({"id" => a.id, "type"=> 'aut'})
    end
    logger.debug("creators #{creators}")
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

  def to_solr(solr_doc = {})
    super
    Solrizer.insert_field(solr_doc, 'display_value',title_values.first, :displayable)
    title_values.each do |val|
      Solrizer.insert_field(solr_doc, 'title', val, :stored_searchable, :displayable)
    end
    authors.each do |aut|
      Solrizer.insert_field(solr_doc, 'author', aut.all_names,:stored_searchable, :facetable, :displayable)
    end
    solr_doc
  end


  # Static methods

  def self.get_title_typeahead_objs
    ActiveFedora::SolrService.query("title_tesim:* && active_fedora_model_ssi:Work",
                                    {:rows => ActiveFedora::SolrService.count("title_tesim:* && active_fedora_model_ssi:Work")})
  end

end
