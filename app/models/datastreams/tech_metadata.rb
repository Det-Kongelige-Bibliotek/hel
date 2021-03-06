# -*- encoding : utf-8 -*-
module Datastreams

  # Datastream for technical content_file metadata
  class TechMetadata < ActiveFedora::OmDatastream

    # Inserted maintain existing naming of solr fields in Activefedora 8
    # And thus avoid annoying deprecation warning messages
    def prefix(*args)
      ""
    end

    set_terminology do |t|
      t.root(:path=>'fields')
      t.uuid(:type => :string, :index_as=>[:stored_searchable, :displayable, :sortable], :label=>'UUID for the Fedora object')
      t.file_checksum
      t.original_filename(:type => :string, :index_as=>[:stored_searchable, :displayable, :sortable], :label=>'Original filename')
      t.external_file_path
      t.mime_type
      t.file_size(:type => :integer, :index_as => :stored_searchable, :label => 'File size', :path=>'file_size')
      t.last_modified
      t.created(:type => :time, :index_as => :stored_searchable, :label => 'Create date')
      t.last_accessed
      t.file_uuid(:type => :string, :index_as=>[:stored_searchable, :displayable, :sortable], :label=>'UUID for the actual file')
      t.editable
      t.validators
      t.pb_xml_id(:type=> :string, :index_as => :stored_searchable)
      t.pb_facs_id(:type=> :string, :index_as=>[:stored_searchable, :displayable, :sortable])
      t.xml_pointer
      t.dissemination_checksums(type: :string)
      # Format metadata extracted from characterization
      t.format_name(:type => :string, :index_as=> [:stored_searchable, :sortable], :label=>'Format name', :path=>'format_name')
      t.format_mimetype(:type => :string, :index_as=> [:stored_searchable, :sortable], :label=>'Format mimetype', :path=>'format_mimetype')
      t.format_version(:type => :string, :index_as=> [:stored_searchable, :sortable], :label=>'Format version', :path=>'format_version')
      t.format_pronom_id(:type => :string, :index_as=> [:stored_searchable, :sortable], :label=>'Pronom ID (format identification)', :path=>'format_pronom_id')
      t.creating_application(:type => :string, :index_as => [:stored_searchable, :sortable], :label => 'Creating Application Name', :path => 'creating_application')
      t.characterization_tools(:type => :text, :index_as => [:stored_searchable], :label => 'Characterization tools', :path => 'characterization_tools')
    end

    def self.xml_template
      Nokogiri::XML.parse('<fields/>')
    end
  end
end
