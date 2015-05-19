# This is a KB Instance.
# Only KB specific logic should
# live in this class. All domain logic
# e.g. Bibframe, Hydra::Rights etc,
# should live in separate modules and
# be mixed in.
class Instance < ActiveFedora::Base
  include Hydra::AccessControls::Permissions
  include Concerns::AdminMetadata
  include Concerns::Preservation
  include Concerns::Renderers
  include Datastreams::TransWalker
#  include Concerns::CustomValidations

  property :languages, predicate: ::RDF::Vocab::Bibframe.language
  property :isbn13, predicate: ::RDF::Vocab::Bibframe.isbn13, multiple: false
  property :isbn10, predicate: ::RDF::Vocab::Bibframe.isbn10, multiple: false
  property :mode_of_issuance, predicate: ::RDF::Vocab::Bibframe.modeOfIssuance, multiple: false
  property :extent, predicate: ::RDF::Vocab::Bibframe.extent, multiple: false
  property :note, predicate: ::RDF::Vocab::Bibframe.note
  property :title_statement, predicate: ::RDF::Vocab::Bibframe.titleStatement, multiple: false
  property :dimensions, predicate: ::RDF::Vocab::Bibframe.dimensions, multiple: false
  property :contents_note, predicate: ::RDF::Vocab::Bibframe.contentsNote, multiple: false

  belongs_to :work, predicate: ::RDF::Vocab::Bibframe::instanceOf

  has_and_belongs_to_many :equivalents, class_name: "Instance", predicate: ::RDF::Vocab::Bibframe::hasEquivalent

  has_many :content_files, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf
  has_many :relators, predicate: ::RDF::Vocab::Bibframe.relatedTo
  has_many :publications, predicate: ::RDF::Vocab::Bibframe::publication, class_name: 'Provider'

  accepts_nested_attributes_for :relators, :publications

  before_save :set_rights_metadata

  def publication
    publications.first
  end
  # method to set the rights metadata stream based on activity
  def set_rights_metadata
    a = Administration::Activity.find(self.activity)
    self.discover_groups = a.activity_permissions['instance']['group']['discover']
    self.read_groups = a.activity_permissions['instance']['group']['read']
    self.edit_groups = a.activity_permissions['instance']['group']['edit']
  end


  def uuid
    self.id
  end

  validates :collection, :copyright, presence: true


  # Use this setter to manage work relations
  # as it ensures relationship symmetry
  # We allow it to take pids as Strings
  # to enable it to be written to via forms
  # @params Work | String (pid)
  def set_work=(work_input)
    if work_input.is_a? String
      work = Work.where(work_input)
    elsif work_input.is_a? Work
      work = work_input
    else
      fail "Can only take args of type Work or String where string represents a Work's pid"
    end
    begin
      self.work = work
      work
    rescue ActiveFedora::RecordInvalid => exception
      logger.error("set_work failed #{exception}")
      nil
    end
  end

  def set_equivalent=(instance_input)
    if instance_input.is_a? String
      instance = Instance.where(instance_input)
    elsif instance_input.is_a? Instance
      instance = instance_input
    else
      fail "Can only take args of type Instance or String where string represents a Work's pid"
    end
    begin
      self.equivalents += [instance]
      instance.equivalents += [self]
      instance
    rescue ActiveFedora::RecordInvalid => exception
      logger.error("set_equivalent failed #{exception}")
      nil
    end
  end
  
  def add_relator(agent,role)
    relation = Relator.new(agent: agent, role: role)
    self.relators += [relation]
  end

  def add_publisher(agent)
    role = 'http://id.loc.gov/vocabulary/relators/pbl'
    self.add_relator(agent,role)
  end

  def add_printer(agent)
    role = 'http://id.loc.gov/vocabulary/relators/prt'
    self.add_relator(agent,role)
  end

  def add_scribe(agent)
    role = 'http://id.loc.gov/vocabulary/relators/scr'
    self.add_relator(agent,role)
  end

  def content_files=(files)
    # ensure instance is valid before saving files
    return unless self.valid?
    #remove old file
    content_files.delete_all
    files.each do |f|
      self.add_file(f)
    end
  end

  def add_file(file, validators=[],run_custom_validators = true)
    cf = ContentFile.new
    cf.instance=self
    if (file.is_a? File) || (file.is_a? ActionDispatch::Http::UploadedFile)
      cf.add_file(file)
    else
      if (file.is_a? String)
        cf.add_external_file(file)
      end
    end
    cf.instance = self
    cf.validators = validators
    cf.save(validate: run_custom_validators)
    cf
  end



  def set_rights_metadata_on_file(file)
    a = Administration::Activity.find(self.activity)
    file.discover_groups = a.permissions['file']['group']['discover']
    file.read_groups = a.permissions['file']['group']['read']
    file.edit_groups = a.permissions['file']['group']['edit']
  end

  ## Model specific preservation functionallity

  # @return whether any operations can be cascading (e.g. updating administrative or preservation metadata)
  # For the instances, this is true (since it has the files).
  def can_perform_cascading?
    true
  end

  # Returns all the files as ContentFile objects.
  # @return the objects, which cascading operations can be performed upon (e.g. updating administrative or preservation metadata)
  def cascading_elements
    res = []
    content_files.each do |f|
      res << ContentFile.find(f.pid)
    end
    logger.debug "Found following inheritable objects: #{res}"
    res
  end

  def create_preservation_message_metadata

    res = "<provenanceMetadata><fields><uuid>#{self.uuid}</uuid></fields></provenanceMetadata>"
    res +="<preservationMetadata>"
    res += self.preservationMetadata.content
    res +="</preservationMetadata>"

    mods = self.to_mods
    if mods.to_s.start_with?('<?xml') #hack to remove XML document header from any XML content
      mods = Nokogiri::XML.parse(mods).root.to_s
    end
    res += mods

    #TODO: Update this to handle multiple file instances with structmaps
    if (self.content_files.size  > 0 )
      cf = content_files.each do |cf|
        res+="<file><name>#{cf.original_filename}</name>"
        res+="<uuid>#{cf.uuid}</uuid></file>"
      end
    end
    res
  end

  def to_solr(solr_doc = {} )
    super
    #activity_name = Administration::Activity.find(activity).activity
    #Solrizer.insert_field(solr_doc, 'activity_name', activity_name, :stored_searchable, :facetable)
  end


  # given an activity name, return a set of Instances
  # belonging to that activity
  # note the mapping to AF objects will take a bit of time
  def self.find_by_activity(activity)
    docs = ActiveFedora::SolrService.query("activity_name_sim:#{activity}")
    docs.map { |d| Instance.find(d['id']) }
  end

  # given an activity object - create an instance
  # with the default values of that activity
  def self.from_activity(activity)
    i = self.new
    i.activity = activity.id
    i.collection = activity.collection
    i.copyright = activity.copyright
    i.preservation_profile = activity.preservation_profile
    i
  end
end
