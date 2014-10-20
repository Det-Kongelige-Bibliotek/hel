module Datastreams
  module Bibframe
    # Datastream for modelling all
    # Bibframe::Instance metadata
    class InstanceMetadata < ActiveFedora::OmDatastream
      set_terminology do |t|
        t.root(path:  'Instance', xmlns: 'http://bibframe.org/vocab/')
        t.language do
          t.authority(path: { attribute: 'authority', namespace_prefix: nil })
        end
        t.note
        t.identifier do
          t.identifierValue
          t.identifierScheme
        end
        t.publication do
          t.publicationNote
          t.publicationDate
        end
        t.distribution do
          t.distributionNote
          t.distributionDate
        end
        t.production do
          t.productionNote
          t.productionDate
        end
        t.isbn_13(path: 'isbn13') do
          t.Identifier do
            t.label
          end
        end

        t.language_authority(proxy: [:language, :authority])
        t.production_note(proxy: [:production, :productionNote])
        t.production_date(proxy: [:production, :productionDate])
        t.distribution_note(proxy: [:distribution, :distributionNote])
        t.distribution_date(proxy: [:distribution, :distributionDate])
        t.publication_note(proxy: [:publication, :publicationNote])
        t.publication_date(proxy: [:publication, :publicationDate])
        t.identifier_value(proxy: [:identifier, :identifierValue])
        t.identifier_scheme(proxy: [:identifier, :identifierScheme])
        t.isbn13(proxy: [:isbn_13, :Identifier, :label])
      end

      define_template :isbn13 do |xml, value|
        xml.isbn13 do
          xml.Identifier do
            xml.label { xml.text(value) }
          end
        end
      end

      def self.xml_template
        Nokogiri::XML.parse('<bf:Instance xmlns:bf="http://bibframe.org/vocab/">')
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
