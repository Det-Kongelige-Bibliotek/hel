module Datastreams
  module MADS
    # This class contains all methods for parsing a MADS XML document.
    # It should be capable of parsing personal, corporate, subject,
    # geographic data etc.
    # See http://www.loc.gov/standards/mads/mads-outline.html
    # for an overview.
    class Document < ActiveFedora::OmDatastream
      set_terminology do |t|
        t.root(path: 'mads', xmlns: 'http://www.loc.gov/mads/v2')
        t.notes(path: 'note')
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
