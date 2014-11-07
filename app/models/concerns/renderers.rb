module Concerns
  # To be mixed in by AF models with Bibframe datastreams
  # Contains methods to produce an RDF representation of object
  # The only publically used method is to_rdf, which is called
  # when the user requests a document in rdf format.
  # The Bibframe Metadata is combined with the Fedora RelsExt
  # and outputted as a single RDF compliant document.
  # <?xml version="1.0"?>
  #       <rdf:RDF xmlns:bf="http://bibframe.org/vocab/#" 
  #       xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" 
  #       xmlns:relators="http://id.loc.gov/vocabulary/relators/#">
  #   <bf:Work rdf:about="http://valhal.kb.dk/resources/valhal:1">
  #   <bf:relatedWork rdf:resource="http://valhal.kb.dk/resources/valhal:3"/>
  #   <relators:aut rdf:resource="http://valhal.kb.dk/resources/valhal:2"/>
  #   <bf:title>
  #     <bf:Title>
  #       <bf:titleType>uniform</bf:titleType>
  #       <bf:titleValue>Great Expectations</bf:titleValue>
  #     </bf:Title>
  #   </bf:title>
  #   <bf:identifier>
  #     <bf:Identifier>
  #       <bf:identifierScheme>uuid</bf:identifierScheme>
  #   <bf:identifierValue>4c168590-4180-0132-e264-101f744d4172</bf:identifierValue>
  #     </bf:Identifier>
  #   </bf:identifier>
  # </bf:Work>
  # </rdf:RDF>

  module Renderers
    BIBFRAME_URI = 'http://bibframe.org/vocab/'
    LOC_RELATORS_URI = 'http://id.loc.gov/vocabulary/relators/'
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

    # This method pulls the rels ext and bibframe data together
    # to create a valid mods representation of the object.
    def to_mods
      fail "mods can only be instantiated for Instances"  unless self.is_a? Instance
      document = Nokogiri::XML(self.to_rdf)
      template = Nokogiri::XSLT(File.read(Rails.root.join('app','export','transforms','bibframe2mods.xsl')))
      transformed_document = template.transform(document)
      transformed_document.to_xml
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
          xml['bf'].send(self.class.to_s, 'rdf:about' => create_resource_url(id)) do
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

    # create a link to a resource based on
    # a Fedora identifier and the application url
    # set in the local config file
    # e.g. from info:fedora/valhal:90
    # to http://valhal.kb.dk/resources/valhal:90
    def create_resource_url(fedora_identifier)
      app_url = CONFIG[Rails.env.to_sym][:application_url]
      system_id = fedora_identifier.split('/').last
      "#{app_url}/resources/#{system_id}"
    end

    # Get all subelements of object as a single string
    def bf_xml
      doc = Nokogiri::XML(bfMetadata.to_xml)
      doc.root.children.to_xml
    end

    # Given a Nokogiri::XML::Document and a namespace uri
    # return a hash of all objects within that namespace,
    # with Fedora links corrected to be Valhal links
    # For example an element in the form:
    # <ns0:relatedWork rdf:resource='info:fedora/valhal:90'/>
    # will be rendered as:
    # { relatedWork: 'http://valhal.kb.dk/resources/valhal:90' }
    def namespaced_relations(doc, namespace_uri)
      val_hash = rip_rdf_statements(doc.xpath('.//ns:*', 'ns' => namespace_uri))
      val_hash.each { |k, v| val_hash[k] = create_resource_url(v) }
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
