# -*- encoding : utf-8 -*-
module Datastreams

  # Datastream for technical content_file metadata
  class TechMetadata < ActiveFedora::OmDatastream

    # Inserted maintain existing naming of solr fields in Activefedora 8
    # And thus avoid anoing deprecation warning messages
    def prefix(*args)
      ""
    end

    set_terminology do |t|
      t.root(:path=>'fields')
      t.uuid
      t.file_checksum
      t.original_filename(:type=> :string, :index_as => :stored_searchable)
      t.external_file_path
      t.mime_type
      t.file_size
      t.last_modified
      t.created
      t.last_accessed
      t.file_uuid
      t.editable
      t.validators
      t.pb_xml_id(:type=> :string, :index_as => :stored_searchable)
      t.pb_facs_id(:type=> :string, :index_as => :stored_searchable)
      t.xml_pointer
    end

    def self.xml_template
      Nokogiri::XML.parse('<fields/>')
    end
  end
end