module Datastreams
  module MADS
    # This class contains all methods for parsing a MADS XML document.
    # It should be capable of parsing personal, corporate, subject,
    # geographic data etc.
    # See http://www.loc.gov/standards/mads/mads-outline.html
    # for an overview.
    class Document < ActiveFedora::OmDatastream

      # Inserted maintain existing naming of solr fields in Activefedora 8
      # And thus avoid anoing deprecation warning messages
      def prefix
        ""
      end

      set_terminology do |t|
        t.root(path: 'mads', xmlns: 'http://www.loc.gov/mads/v2')
        t.notes(path: 'note')
        t.identifiers(path: 'identifier')
        t.uuid(path: 'identifier', attributes: { type: 'uuid' })
        t.authority do
          t.name do
            t.authority_type(path: { attribute: 'authority' })
            t.family(path: 'namePart', attributes: { type: 'family' })
            t.given(path: 'namePart', attributes: { type: 'given' })
            t.date(path: 'namePart', attributes: { type: 'date' })
            t.full(path: 'namePart', attributes: { type: :none })
          end
        end
        t.variant do
          t.name do
            t.family(path: 'namePart', attributes: { type: 'family' })
            t.given(path: 'namePart', attributes: { type: 'given' })
            t.date(path: 'namePart', attributes: { type: 'date' })
            t.full(path: 'namePart', attributes: { type: :none })
          end
        end
      end

      define_template :authorized_person do |xml, name_hash|
        xml.authority do
          # get authority value from scheme key and remove from hash
          xml.name(type: 'personal', authority: name_hash.delete('scheme')) do
            name_hash.each do |key, val|
              if key == :full
                xml.namePart { xml.text(val) }
              else
                xml.namePart(type: key.to_s) { xml.text(val) }
              end
            end
          end
        end
      end

      # Given a hash of values, add a new authorized personal name
      # based on a pre-defined template e.g.
      # {scheme: 'viaf', family: 'Joyce', given: 'James', date: '1882-1941'}
      # will insert and return an xml node with the following structure
      # <mads:authority>
      #   <mads:name type="personal" authority="viaf">
      #     <mads:namePart type="family">Joyce</mads:namePart>
      #     <mads:namePart type="given">James</mads:namePart>
      #     <mads:namePart type="date">1882-1941</mads:namePart>
      #   </mads:name>
      # </mads:authority>
      def add_authorized_personal_name(name_hash)
        ensure_valid_name_hash!(name_hash)
        node = add_child_node(ng_xml.root, :authorized_person, name_hash)
        content_will_change!
        node
      end

      # throws an exception if the hash does not have the necessary data
      def ensure_valid_name_hash!(name_hash)
        #fail 'You must provide an authority scheme' unless name_hash[:scheme].present?
        unless name_hash['family'].present? || name_hash['given'].present? || name_hash['full'].present?
          fail 'You must provide at least one name'
        end
      end

      # Return a hash of hashes
      # whereby each hash contains the
      # components of a name element
      # ordered by their types.
      # The first-level hash key is the authority type.
      # If there is no authority type, we use an index.
      # e.g. { naf: {family: 'Getz', given: 'Stanley', date: '1927'}}
      def authorized_personal_names
        authorized = {}
        authority.name.nodeset.each_with_index do |node, i|
          type = node.attr('authority').to_sym || i
          authorized[type] = parse_names(node)
        end
        authorized
      end

      def other_personal_names
        other_names = []
        variant.name.nodeset.each do |node|
          other_names << parse_names(node)
        end
        other_names
      end

      # Return an identifier of a given scheme
      # if present, otherwise nil
      # @param String
      # @return String | nil
      def identifier(scheme)
        identifiers.nodeset.each do |n|
          return n.text if n.attr('type').present? && n.attr('type') == scheme
        end
        nil
      end

      def self.xml_template
        Nokogiri::XML.parse('<mads:mads version="2.0" xmlns:mads="http://www.loc.gov/mads/v2">')
      end

      private

      # given a mads:name element,
      # parse the subelements
      # and return a hash organised
      # by element type
      # @param Nokogiri::XML::Node
      # @return Hash
      # e.g. {family: 'Getz', given: 'Stan'}
      def parse_names(node)
        h = {}
        family = fetch_name_type(node, 'family')
        given = fetch_name_type(node, 'given')
        date = fetch_name_type(node, 'date')
        full = fetch_name_type(node)
        h.merge!(family) unless family.nil?
        h.merge!(given) unless given.nil?
        h.merge!(date) unless date.nil?
        h.merge!(full) unless full.nil?
        h
      end

      # Given a node and a name type, find the
      # nearest namePart with that type
      def fetch_name_type(node, type = nil)
        # if we have a type, find that type
        # otherwise find the namePart with no type
        if type
          elem = node.xpath('mads:namePart[@type=$value]', nil, value: type)
        else
          type = 'full'
          elem = node.xpath('mads:namePart[not(@*)]')
        end
        return nil unless elem.text.present?
        { type.to_sym => elem.text }
      end
    end
  end
end
