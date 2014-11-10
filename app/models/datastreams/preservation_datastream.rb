# -*- encoding : utf-8 -*-
module Datastreams
  # Datastream for the preservation metadata. It is just a simple XML-formatted key-value mapping.
  class PreservationDatastream < ActiveFedora::OmDatastream

    # Inserted maintain existing naming of solr fields in Activefedora 8
    # And thus avoid anoing deprecation warning messages
    def prefix
      ""
    end

    set_terminology do |t|
      t.root(path: 'fields')
      t.preservation_profile(:type => :string, :index_as=>[:stored_searchable, :displayable, :sortable],
                             :path=>'preservation_profile', :label=>'Preservation Profile')
      t.preservation_state(:type => :string, :index_as=>[:stored_searchable, :displayable, :sortable],
                           :path=>'preservation_state', :label=>'Preservation State')
      t.preservation_details(:type => :string, :index_as=>[:stored_searchable, :displayable],
                             :path=>'preservation_details', :label=>'Preservation Details')
      t.preservation_modify_date(:type => :string, :index_as => [:stored_searchable, :displayable, :sortable],
                                 :path => 'preservation_modify_date', :label => 'Preservation Modify Date')
      t.preservation_comment(:type => :string, :index_as => [:stored_searchable, :displayable, :sortable],
                             :path => 'preservation_comment', :label => 'Preservation Comment')
      t.warc_id(:type => :string, :index_as => [:stored_searchable, :displayable, :sortable],
                :path => 'warc_id', :label => 'Warc ID')
      t.preservation_bitsafety(:type => :string, :index_as => [:stored_searchable, :displayable, :sortable],
                               :path => 'preservation_bitsafety', :label => 'Preservation BitSafety')
      t.preservation_confidentiality(:type => :string, :index_as => [:stored_searchable, :displayable, :sortable],
                               :path => 'preservation_confidentiality', :label => 'Preservation Confidentiality')
    end

    def self.xml_template
      Nokogiri::XML.parse('<fields/>')
    end
  end
end