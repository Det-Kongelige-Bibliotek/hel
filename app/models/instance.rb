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
  belongs_to :work, property: :instance_of
  has_many :content_files, property: :content_for
  has_metadata :name => 'preservationMetadata', :type => Datastreams::PreservationDatastream
  has_attributes :preservation_profile, :preservation_state, :preservation_details, :preservation_modify_date,
                    :preservation_comment, :warc_id, :preservation_bitsafety, :preservation_confidentiality,
                    datastream: 'preservationMetadata', :multiple => false

  before_validation(:on => :create) do
    self.preservation_profile = 'Undefined' if preservation_profile.blank?
    self.preservation_state = Constants::PRESERVATION_STATE_NOT_STARTED.keys.first if preservation_state.blank?
    self.preservation_details = 'N/A' if preservation_details.blank?
    set_preservation_modified_time(self)
  end
  
  # @return whether any operations can be cascading (e.g. updating administrative or preservation metadata)
  # For the instances, this is true (since it has the files).
  def can_perform_cascading?
    true
  end

  # Check whether it should be cascading, and also perform the cascading.
  # @param params The parameter from the controller. Contains the parameter for whether the preservation
  # should be cascaded.
  # @param element The element to have stuff cascaded.
  # TODO: this is broken - fix it!
  def cascade_preservation(params, element)
    return unless element.can_perform_cascading? && params['preservation']['cascade_preservation'] == Constants::CASCADING_EFFECT_TRUE
    element.cascading_elements.each do |pib|
      update_preservation_profile_from_controller(params, pib)
    end
  end
end
