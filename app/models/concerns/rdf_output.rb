module Concerns
  # To be mixed in by AF models with Bibframe datastreams
  # Contains methods to produce an RDF representation of object
  module RDFOutput
    BIBFRAME_URI = 'http://bibframe.org/vocab/#'
    LOC_RELATORS_URI = 'http://id.loc.gov/vocabulary/relators/#'
    RDF_URI =  'http://www.w3.org/1999/02/22-rdf-syntax-ns#'

    # This method pulls the rels ext and bibframe data together
    # to create a valid RDF representation of the object.
    def to_rdf
      # Get all our Fedora relations and parse to hashes
      relations = Nokogiri::XML(rels_ext.to_rels_ext)
      relator_vals = namespaced_relations(relations, LOC_RELATORS_URI)
      bf_vals = namespaced_relations(relations, BIBFRAME_URI)
      output = build_rdf_xml(bf_vals, relator_vals, bf_xml)
      correct_root_element(output)
    end

    # We create a new document with the correct namespaces and
    # add all our data.
    # It's a long method - I think it's as clean as I can make it
    # Suggestions always welcome
    # rubocop:disable Metrics/MethodLength
    def build_rdf_xml(bf_rels, loc_rels, other_metadata)
      builder = Nokogiri::XML::Builder.new do |xml|
        xml['rdf'].rdf('xmlns:bf' => BIBFRAME_URI,
                       'xmlns:rdf' => RDF_URI,
                       'xmlns:relators' => LOC_RELATORS_URI
        ) do
          #  Use .class method to make it class agnostic
          xml['bf'].send(self.class.to_s) do
            # Add the relational data
            bf_rels.each do |key, val|
              xml['bf'].send(key, 'rdf:resource' => val)
            end
            loc_rels.each do |key, val|
              xml['relators'].send(key, 'rdf:resource' => val)
            end
            # append all the data from the bfMetadata stream
            xml << other_metadata
          end
        end
      end
      builder.to_xml
    end
    # rubocop:enable Metrics/MethodLength

    # Get all subelements of object as a single string
    def bf_xml
      doc = Nokogiri::XML(bfMetadata.to_xml)
      doc.root.children.to_xml
    end

    # Given a Nokogiri::XML::Document and a namespace uri
    # return a hash of all objects within that namespace.
    # For example an element in the form:
    # <ns0:relatedWork rdf:resource='someresource.com'/>
    # will be rendered as:
    # { relatedWork: 'someresource.com' }
    def namespaced_relations(doc, namespace_uri)
      rip_rdf_statements(doc.xpath('.//ns:*', 'ns' => namespace_uri))
    end

    def rip_rdf_statements(nodeset)
      h = {}
      nodeset.each do |n|
        h[n.name] = n['rdf:resource']
      end
      h
    end

    # Nokogiri won't let us use rdf:RDF construct
    # so we cheat and do it like this.
    def correct_root_element(xml)
      xml.gsub('rdf:rdf', 'rdf:RDF')
    end
  end
end
