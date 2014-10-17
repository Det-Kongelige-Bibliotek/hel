module Datastreams
  module Bibframe
    # Datastream for modelling all Bibframe::Work metadata
    class WorkMetadata < ActiveFedora::OmDatastream
      set_terminology do |t|
        t.root(path:  'Work', xmlns: 'http://bibframe.org/vocab/')
        t.workTitle do
          t.Title do
            t.titleValue
            t.subtitle
          end
        end
        t.language do
          t.authority(path: { attribute: 'authority', namespace_prefix: nil })
        end

        t.note
        t.subject do
          t.Topic do
            t.label
          end
        end

        t.systemNumber do
          t.Identifier do
            t.identifierValue
          end
        end

        t.title(proxy: [:workTitle, :Title, :titleValue])
        t.subtitle(proxy: [:workTitle, :Title, :subtitle])
        t.language_authority(proxy: [:language, :authority])
      end

      define_template :uuid do |xml, uuid_val|
        xml.systemNumber do
          xml.Identifier do
            xml.identifierScheme { xml.text('systemNumber') }
            xml.identifierValue  { xml.text(uuid_val) }
          end
        end
      end

      def uuid
        systemNumber.Identifier.identifierValue.nodeset.each do |n|
          return n.text.sub('(uuid)', '') if n.text.include?('(uuid)')
        end
        nil
      end

      def uuid=(val)
        uuid_val = '(uuid)' + val
        node = add_child_node(ng_xml.root, :uuid, uuid_val)
        content_will_change!
        node
      end

      def self.xml_template
        Nokogiri::XML.parse('<bf:Work xmlns:bf="http://bibframe.org/vocab/">')
      end
    end
  end
end
