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

  belongs_to :work, property: :instance_of, inverse_of: :has_instance
  has_many :content_files, property: :content_for
  has_and_belongs_to_many :parts, class_name: 'Work', property: :has_part, inverse_of: :is_part_of

  validates :activity, :collection, :copyright, presence: true

  # Use this setter to manage work relations
  # as it ensures relationship symmetry
  def set_work(work)
    work.instances << self
    self.work = work
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
