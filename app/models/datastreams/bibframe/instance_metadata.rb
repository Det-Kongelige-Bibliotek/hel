module Datastreams
  module Bibframe
    # Datastream for modelling all
    # Bibframe::Instance metadata
    class InstanceMetadata < Datastreams::Bibframe::Resource

      # Inserted maintain existing naming of solr fields in Activefedora 8
      # And thus avoid anoing deprecation warning messages
      def prefix
        ""
      end

      set_terminology do |t|
        t.root(path:  'Instance', xmlns: 'http://bibframe.org/vocab/')
        t.note
        t.identifier do
          t.Identifier
        end
        t.publication do
          t.Provider do
            t.copyrightDate
            t.providerDate
          end
        end
        t.isbn_13(path: 'isbn13') do
          t.Identifier do
            t.label
          end
        end
        t.language do
          t.Language
        end
        t.mode_of_issuance(path: 'modeOfIssuance')
        t.title_statement(path: 'titleStatement', index_as: :stored_searchable)
        t.extent
        t.dimensions
        t.contents_note(path: 'contentsNote')
        t.isbn13(proxy: [:isbn_13, :Identifier, :label])
        t.copyright_date(proxy: [:publication, :Provider, :copyrightDate])
        t.published_date(proxy: [:publication, :Provider, :providerDate])
      end

      define_template :isbn13 do |xml, value|
        xml.isbn13 do
          xml.Identifier do
            xml.label { xml.text(value) }
          end
        end
      end

      def self.xml_template
        Nokogiri::XML.parse('<bf:Instance xmlns:bf="http://bibframe.org/vocab/"/>')
      end

      # return a hash of identifiers such that
      # identifierScheme is the key and identifierValue
      # the value
      # Necessary to preserve correct ordering.
      def identifier_set
        ids = {}
        identifier.nodeset.each do |n|
          scheme = n.css('bf|identifierScheme').present? ?  n.css('bf|identifierScheme').text : nil
          val = n.css('bf|identifierValue').present? ? n.css('bf|identifierValue').text : nil
          ids[scheme.to_sym] = val if scheme && val
        end
        ids
      end
    end
  end
end
