module Bibframe
  # All Bibframe specific logic for Works
  # should live in this module
  module Instance
    extend ActiveSupport::Concern
    include Bibframe::Concerns::MetadataDelegation

    included do
      fail 'The host class must extend ActiveFedora::Base!' unless self < ActiveFedora::Base
      has_metadata(name: 'bfMetadata',
                   type: Datastreams::Bibframe::InstanceMetadata)

      has_attributes :note, datastream: 'bfMetadata', multiple: true
      has_attributes :copyright_date, :published_date, :isbn13, :mode_of_issuance, :title_statement,
                     :contents_note, :extent, :dimensions, datastream: 'bfMetadata', multiple: false

    end
  end
end
