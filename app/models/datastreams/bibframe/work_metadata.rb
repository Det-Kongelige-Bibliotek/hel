module Datastreams
  module Bibframe
    # Datastream for modelling all Bibframe::Work metadata
    class WorkMetadata < Datastreams::Bibframe::Resource
      set_terminology do |t|
        t.root(path:  'Work', xmlns: 'http://bibframe.org/vocab/')
        t.title do
          t.Title
        end
        t.note
        t.identifier do
          t.Identifier
        end
        t.language do
          t.Language
        end
      end

      define_template :title do |xml, type, subtitle, lang, value|
        xml.title do
          xml.Title do
            lang_attr = lang.present? ? { 'xml:lang' => lang } : {}
            xml.titleType { xml.text(type) }
            xml.titleValue(lang_attr) { xml.text(value) }
            xml.subtitle(lang_attr)  { xml.text(subtitle) } unless subtitle.blank?
          end
        end
      end

      # Create an Array of Title objects
      # based on the title.Title nodeset
      def titles
        title.Title.nodeset.map { |n| Title.new(n) }
      end

      # Return only the title values - useful for indexing
      def title_values
        titles.map(&:value)
      end

      # Add a title to the datastream, expects a Hash
      # with the following keys:
      # { value: 'The Importance of Being Earnest', type: 'Uniform',
      #  subtitle: 'and other encounters', lang: 'en' }
      # Note that value is the only necessary key
      # but the others are important as well!
      # Note also that lang refers to the language of the titleValue
      # not the lang of the resource
      def add_title(title_hash)
        sibling = find_by_terms(:title).last
        if sibling
          node = add_next_sibling_node(sibling, :title, title_hash[:type], title_hash[:subtitle],
                                       title_hash[:lang], title_hash[:value])
        else
          node = add_child_node(ng_xml.root, :title, title_hash[:type], title_hash[:subtitle],
                                title_hash[:lang], title_hash[:value])
        end
        content_will_change!
        node
      end

      def remove_titles
        title.nodeset.each {|n| n.remove}
        content_will_change!
      end

      def self.xml_template
        Nokogiri::XML.parse('<bf:Work xmlns:bf="http://bibframe.org/vocab/"/>')
      end
    end
  end
end
