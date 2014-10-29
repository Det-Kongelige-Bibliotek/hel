module Datastreams
  module Bibframe
    # Common Bibframe metadata elements
    # i.e. those that relate to Resource
    # and the methods to work on them
    # http://bibframe.org/vocab/Resource.html
    class Resource < ActiveFedora::OmDatastream
      set_terminology do |t|
        t.root(path:  'Resource', xmlns: 'http://bibframe.org/vocab/')
        t.identifier do
          t.Identifier
        end
        t.language do
          t.Language
        end
      end

      define_template :identifier do |xml, scheme, value|
        xml.identifier do
          xml.Identifier do
            xml.identifierScheme { xml.text(scheme) }
            xml.identifierValue  { xml.text(value) }
          end
        end
      end

      define_template :language do |xml, part, label|
        xml.language do
          xml.Language do
            xml.resourcePart { xml.text(part) } if part.present?
            xml.label { xml.text(label) }
          end
        end
      end

      def add_identifier(id_hash)
        ensure_scheme_not_present!(id_hash[:scheme])
        add_to_sibling(:identifier, :identifier, id_hash[:scheme], id_hash[:value])
      end

      def identifiers
        identifiers = {}
        identifier_nodeset.each do |n|
          scheme = n.css('bf|identifierScheme').text
          identifiers[scheme.to_sym] = n.css('bf|identifierValue').text
        end
        identifiers
      end

      def uuid
        identifiers[:uuid]
      end

      def uuid=(val)
        add_identifier(scheme: 'uuid', value: val)
      end

      def languages
        languages = []
        language_nodeset.each do |n|
          part = n.css('bf|resourcePart').present? ? n.css('bf|resourcePart').text : nil
          value = n.css('bf|label').text
          languages << Language.new(part, value)
        end
        languages
      end

      def language_values
        languages.map(&:value)
      end

      def add_language(lang)
        add_to_sibling(:language, :language, lang[:part], lang[:value])
      end

      # Add element after sibling if present
      # otherwise, add to root node.
      def add_to_sibling(sibling, template, *vals)
        sibling = find_by_terms(sibling).last
        if sibling
          node = add_next_sibling_node(sibling, template, *vals)
        else
          node = add_child_node(ng_xml.root, template, *vals)
        end
        content_will_change!
        node
      end

      def identifier_nodeset
        identifier.Identifier.nodeset
      end

      def language_nodeset
        language.Language.nodeset
      end

      def self.xml_template
        Nokogiri::XML.parse('<bf:Resource xmlns:bf="http://bibframe.org/vocab/"/>')
      end

      # represents Language elements
      class Language
        attr_accessor :part, :value

        def initialize(part, value)
          @part = part
          @value = value
        end
      end

      protected

      # Given an identifier scheme,
      # delete any identifier already containing this scheme
      def ensure_scheme_not_present!(scheme)
        identifier_nodeset.each do |n|
          id_scheme = n.css('bf|identifierScheme').text
          n.remove if id_scheme == scheme
        end
        content_will_change!
      end
    end
  end
end
