# -*- encoding : utf-8 -*-
module Datastreams
  # Datastream for the preservation metadata. It is just a simple XML-formatted key-value mapping.
  class PreservationDatastream < ActiveFedora::OmDatastream

    # Inserted maintain existing naming of solr fields in Activefedora 8
    # And thus avoid annoying deprecation warning messages
    def prefix(*args)
      ""
    end

    set_terminology do |t|
      t.root(path: 'fields')
      t.preservation_collection(:type => :string, :index_as=>[:stored_searchable, :displayable, :sortable],
                             :path=>'preservation_collection', :label=>'Preservation Collection')
      t.preservation_state(:type => :string, :index_as=>[:stored_searchable, :displayable, :sortable],
                           :path=>'preservation_state', :label=>'Preservation State')
      t.preservation_details(:type => :string, :index_as=>[:stored_searchable, :displayable],
                             :path=>'preservation_details', :label=>'Preservation Details')
      t.preservation_modify_date(:type => :string, :index_as => [:stored_searchable, :displayable, :sortable],
                                 :path => 'preservation_modify_date', :label => 'Preservation Modify Date')
      t.preservation_initiated_date(:type => :string, :index_as => [:stored_searchable, :displayable, :sortable],
                                    :path => 'preservation_initiated_date', :label => 'Preservation Initiated Date')
      t.preservation_comment(:type => :string, :index_as => [:stored_searchable, :displayable, :sortable],
                             :path => 'preservation_comment', :label => 'Preservation Comment')
      t.warc_id(:type => :string, :index_as => [:stored_searchable, :displayable, :sortable],
                :path => 'warc_id', :label => 'Warc ID')
      t.warc_offset(:type => :string)
      t.file_warc_id(:type => :string, :index_as => [:stored_searchable, :displayable, :sortable],
                :path => 'file_warc_id', :label => 'File Warc ID')
      t.file_warc_offset(:type => :string)
      t.preservation_bitsafety(:type => :string, :index_as => [:stored_searchable, :displayable, :sortable],
                               :path => 'preservation_bitsafety', :label => 'Preservation BitSafety')
      t.preservation_confidentiality(:type => :string, :index_as => [:stored_searchable, :displayable, :sortable],
                               :path => 'preservation_confidentiality', :label => 'Preservation Confidentiality')

      t.update {
        t.warc_id()
        t.uuid()
        t.warc_offset()
        t.date()
        t.file_uuid()
        t.file_warc_id()
        t.file_warc_offset()
      }

      t.import_token()
      t.import_token_timeout()
      t.import_state()
      t.import_details()
      t.import_update_date()
    end

    define_template :update do |xml, val|
      xml.update() {
        xml.warc_id {xml.text(val['warc_id'])}
        xml.uuid {xml.text(val['uuid'])}
        xml.warc_offset {xml.text(val['warc_offset'])}
        xml.date {xml.text(val['date'])}
        xml.file_uuid {xml.text(val['file_uuid'])}
        xml.file_warc_id {xml.text(val['file_warc_id'])}
        xml.file_warc_offset {xml.text(val['file_warc_offset'])}
      }
    end

    # Ignores a duplicate UUIDs, both for 'uuid' and for 'file_uuid' fields.
    # @param val Must be a Hash containing at least 'uuid'.
    def insert_update(val)
      raise ArgumentError.new 'Can only create the update element from a Hash map' unless val.is_a? Hash
      raise ArgumentError.new 'Requires a \'uuid\' or \'file_uuid\' field in the Hash map to create the update element' if val['uuid'].blank? && val['file_uuid'].blank?
      duplicate = find_by_terms_and_value(:update, :uuid => val['uuid']) || find_by_terms_and_value(:update, :file_uuid => val['file_uuid'])

      if duplicate.blank?
        sibling = find_by_terms(:update).last

        node = sibling ? add_next_sibling_node(sibling, :update, val) :
            add_child_node(ng_xml.root, :update, val)
        content_will_change!
        node
      end
    end

    def get_updates
      updates = []
      nodes = find_by_terms(:update)
      nodes.each do |n|
        at = Hash.new
        n.children.each do |c|
          at[c.name] = c.text unless c.name == 'text'
        end
        updates << at
      end
      updates
    end

    def self.xml_template
      Nokogiri::XML.parse('<fields/>')
    end
  end
end