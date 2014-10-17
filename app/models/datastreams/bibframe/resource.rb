module Datastreams
  module Bibframe
    # Common Bibframe metadata elements
    # i.e. those that relate to Resource
    # and the methods to work on them
    # http://bibframe.org/vocab/Resource.html
    class Resource < ActiveFedora::OmDatastream
      set_terminology do |t|
        t.root(path:  'Resource', xmlns: 'http://bibframe.org/vocab/')
        t.systemNumber do
          t.Identifier do
            t.identifierValue
          end
        end
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
        Nokogiri::XML.parse('<bf:Resource xmlns:bf="http://bibframe.org/vocab/">')
      end
    end
  end
end
