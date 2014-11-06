# -*- encoding : utf-8 -*-
module Concerns
  # The preservation definition which is to be used by all elements.
  # Adds the preservation metadata datastream, and sets up default values.
  module Preservation
    extend ActiveSupport::Concern

    included do
      include ActiveFedora::Callbacks # to be able to define the 'before_validation' method
      include PreservationHelper # only for method: set_preservation_time

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
    end
  end
end