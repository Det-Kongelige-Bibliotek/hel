module Bibframe
  # All Bibframe specific logic for Works
  # should live in this module
  module Work
    extend ActiveSupport::Concern
    included do
      has_metadata(name: 'bfMetadata',
                   type: Datastreams::Bibframe::WorkMetadata)
      has_attributes(:title, :subtitle,
                     datastream: 'bfMetadata', multiple: false)
      has_attributes(:language, :language_authority, :note,
                     datastream: 'bfMetadata', multiple: true)

      def uuid
        bfMetadata.uuid
      end

      def uuid=(val)
        bfMetadata.uuid = val
      end
    end
  end
end
