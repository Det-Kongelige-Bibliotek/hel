# -*- encoding : utf-8 -*-
module Concerns
  # Handles the technical metadata.
  module TechMetadata
    extend ActiveSupport::Concern

    included do
      has_metadata :name => 'techMetadata', :type => Datastreams::TechMetadata

      has_attributes :uuid, :last_modified, :created, :last_accessed, :original_filename, :mime_type, :file_uuid, :editable, :tei_ref,
                     datastream: 'techMetadata', :multiple => false
      # TODO have more than one checksum (both MD5 and SHA), and specify their checksum algorithm.
      has_attributes :checksum, datastream: 'techMetadata', :at => [:file_checksum], :multiple => false
      has_attributes :size, datastream: 'techMetadata', :at => [:file_size], :multiple => false
      has_attributes :validators, datastream: 'techMetadata', :at => [:validators], :multiple => true
    end
  end
end


