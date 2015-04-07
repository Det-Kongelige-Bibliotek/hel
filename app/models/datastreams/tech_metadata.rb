# -*- encoding : utf-8 -*-
module Datastreams

  # Datastream for technical content_file metadata
  class TechMetadata < ActiveFedora::OmDatastream

    # Inserted maintain existing naming of solr fields in Activefedora 8
    # And thus avoid annoying deprecation warning messages
    def prefix
      ""
    end

    set_terminology do |t|
      t.root(:path=>'fields')
      t.uuid(:type => :string, :index_as=>[:stored_searchable, :displayable, :sortable], :label=>'UUID for the Fedora object')
      t.file_checksum
      t.original_filename(:type => :string, :index_as=>[:stored_searchable, :displayable, :sortable], :label=>'Original filename')
      t.mime_type
      t.file_size
      t.last_modified
      t.created
      t.last_accessed
      t.file_uuid(:type => :string, :index_as=>[:stored_searchable, :displayable, :sortable], :label=>'UUID for the actual file')
      t.editable
      t.validators
      t.pb_xml_id(:type=> :string, :index_as => :stored_searchable)
      t.pb_facs_id(:type=> :string, :index_as => :stored_searchable)
      # Format metadata extracted from characterization
      t.format_name(:type => :string, :index_as=>[:stored_searchable, :displayable, :sortable], :label=>'Format name', :path=>'format_name')
      t.format_mimetype(:type => :string, :index_as=>[:stored_searchable, :displayable, :sortable], :label=>'Format mimetype', :path=>'format_mimetype')
      t.format_version(:type => :string, :index_as=>[:stored_searchable, :displayable, :sortable], :label=>'Format version', :path=>'format_version')
    end

    def self.xml_template
      Nokogiri::XML.parse('<fields/>')
    end
  end
end