# This is a KB Instance.
# Only KB specific logic should
# live in this class. All domain logic
# e.g. Bibframe, Hydra::Rights etc,
# should live in separate modules and
# be mixed in.
class Instance < ActiveFedora::Base
  include Bibframe::Instance
  include Hydra::AccessControls::Permissions
  include Concerns::AdminMetadata
  include Concerns::UUIDGenerator
  include Concerns::Preservation
  include Concerns::Renderers
  include Datastreams::TransWalker

  has_and_belongs_to_many :work, class_name: 'Work', property: :instance_of, inverse_of: :has_instance
  has_many :content_files, property: :content_for
  has_and_belongs_to_many :parts, class_name: 'Work', property: :has_part, inverse_of: :is_part_of

  validates :activity, :collection, :copyright, presence: true

  before_save :set_rights_metadata

  # Use this setter to manage work relations
  # as it ensures relationship symmetry
  # We allow it to take pids as Strings
  # to enable it to be written to via forms
  # @params Work | String (pid)
  def set_work=(work_input)
    if work_input.is_a? String
      work = Work.find(work_input)
    elsif work_input.is_a? Work
      work = work_input
    else
      fail "Can only take args of type Work or String where string represents a Work's pid"
    end
    begin
     # work.instances << self
      self.work << work
      work
    rescue ActiveFedora::RecordInvalid => exception
      logger.error("set_work failed #{exception}")
      nil
    end
  end

  # This is actually a getter!
  # In order to wrap work= as above, we also
  # need to provide a reader for our form input
  # It returns an id because this is what is used
  # in the form.
  def set_work
    work.first.id
  end

  # very simple method to enable
  # single file uploads
  # will need to be expanded to handle
  # multiple files
  def content_files=(file)
    #remove old file
    content_files.each do |cf|
      cf.delete
    end

    cf = ContentFile.new
    cf.add_file(file)
    set_rights_metadata_on_file(cf)
    cf.save
    content_files << cf
  end

  # method to set the rights metadata stream based on activity
  def set_rights_metadata
    a = Administration::Activity.find(self.activity)
    self.discover_groups = a.permissions['instance']['group']['discover']
    self.read_groups = a.permissions['instance']['group']['read']
    self.edit_groups = a.permissions['instance']['group']['edit']
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
    puts "looking for cascading elements"
    content_files.each do |f|
      puts "adding a content file"
      res << ContentFile.find(f.pid)
    end
    puts "Found following inheiritable objects: #{res}"
    logger.debug "Found following inheiritable objects: #{res}"
    res
  end

  def create_preservation_message_metadata

    res = "<provenanceMetadata><fields><uuid>#{self.uuid}</uuid></fields></provenanceMetadata>"
    res +="<preservationMetadata>"
    res += self.preservationMetadata.content
    res +="</preservationMetadata>"

    mods = self.to_mods
    if mods.to_s.start_with?('<?xml') #hack to remove XML document header from any XML content
      logger.debug("removing xml header")
      mods = Nokogiri::XML.parse(mods).root.to_s
    end
    res += mods

    #TODO: Update this to handle multiple file instances with structmaps
    if (self.content_files.size == 1)
      cf = content_files.first
      res+="<file><name>#{cf.original_filename}</name>"
      res+="<uuid>#{cf.uuid}</uuid></file>"
    end
  end
end
