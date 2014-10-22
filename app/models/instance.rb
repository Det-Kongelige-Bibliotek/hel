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

  belongs_to :work, property: :instance_of
  has_many :content_files, property: :content_for

  # @return whether any operations can be cascading (e.g. updating administrative or preservation metadata)
  # For the instances, this is true (since it has the files).
  def can_perform_cascading?
    true
  end

  # Returns all the files as ContentFile objects.
  # @return the objects, which cascading operations can be performed upon (e.g. updating administrative or preservation metadata)
  def cascading_elements
    res = []
    self.content_files.each do |f|
      res << ContentFile.find(f.pid)
    end
    logger.debug "Found following inheiritable objects: #{res.to_s}"
    res
  end

end
