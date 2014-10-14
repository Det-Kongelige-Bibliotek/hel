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
        t.authority do
          t.name do
            t.family(path: 'namePart', attributes: { type: 'family' })
            t.given(path: 'namePart', attributes: { type: 'given' })
            t.date(path: 'namePart', attributes: { type: 'date' })
            t.full(path: 'namePart', attributes: { type: :none })
          end
        end
      end

      def self.xml_template
        Nokogiri::XML.parse('<mads:mads version="2.0" xmlns:mads="http://www.loc.gov/mads/v2">')
      end
    end
  end
end
