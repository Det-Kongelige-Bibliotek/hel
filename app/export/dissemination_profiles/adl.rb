module DisseminationProfiles
  # A Dissemination profile is a class that is
  # responsible for publishing content to a public facing platform.
  # This may be a file server, Solr index etc
  # It must have one method disseminate. This takes an instance as its argument.
  class Adl
    def self.disseminate(instance)
      puts "disseminating #{instance.id}"
    end

    # Given a path to a TEI file, call the XSLT
    # script on it
    def self.transform(tei_file_path)
      doc = Nokogiri::XML(File.read(tei_file_path))
      filename = Pathname.new(tei_file_path).basename.to_s
      stylesheet_path = Rails.root.join('app', 'export', 'transforms', 'adder.xsl')
      stylesheet = Nokogiri::XSLT(File.read(stylesheet_path))
      stylesheet.transform(doc, ['file', "'#{filename}'", 'uri_base', "'http://adl.kb.dk/'"]) #
    end

    # Given a solr doc in XML, add to solr index
    def self.add_to_solr(solr_doc)
      solr = RSolr.connect :url => CONFIG[:external_solr]
      solr.update(data: solr_doc)
      solr.commit
    end

    def self.transform_and_disseminate(tei_file_path)
      doc = self.transform(tei_file_path)
      self.add_to_solr(doc)
    end
  end
end
