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

  belongs_to :work, property: :instance_of
  has_many :content_files, property: :content_for
  has_and_belongs_to_many :parts, class_name: 'Work', property: :has_part, inverse_of: :is_part_of

  validates :activity, :collection, :copyright, presence: true

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
      work.instances << self
      work.save
      self.work = work
      save
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
    work.id
  end

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
    logger.debug "Found following inheiritable objects: #{res}"
    res
  end

  # very simple method to enable
  # single file uploads
  # will need to be expanded to handle
  # multiple files
  def content_files=(file)
    cf = ContentFile.new
    cf.file.content = file
    content_files << cf
  end
end
