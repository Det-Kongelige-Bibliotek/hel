module Bibframe
  # All Bibframe specific logic for Works
  # should live in this module
  module Work
    extend ActiveSupport::Concern
    include Bibframe::Concerns::MetadataDelegation

    included do
      fail 'The host class must extend ActiveFedora::Base!' unless self < ActiveFedora::Base

      has_metadata name: 'bfMetadata', type: Datastreams::Bibframe::WorkMetadata
      has_attributes :note, datastream: 'bfMetadata', multiple: true

    end
  end
end
