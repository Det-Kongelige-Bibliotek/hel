module Bibframe
  # All Bibframe specific logic for Works
  # should live in this module
  module Instance
    extend ActiveSupport::Concern
    included do
      has_metadata(name: 'bfMetadata',
                   type: Datastreams::Bibframe::InstanceMetadata)
      has_attributes(:production_note, :production_date,
                     :publication_note, :publication_date,
                     :distribution_note, :distribution_date,
                     :isbn13,
                     datastream: 'bfMetadata', multiple: false)
      has_attributes(:language, :language_authority, :note,
                     :identifier_value, :identifier_scheme,
                     datastream: 'bfMetadata', multiple: true)
    end
  end
end
