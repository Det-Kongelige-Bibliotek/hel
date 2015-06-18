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
    def self.transform(tei_file)
      puts tei_file
      doc = Nokogiri::XML(File.read(tei_file))
      stylesheet_path = Rails.root.join('app', 'export', 'transforms', 'adder.xsl')
      stylesheet = Nokogiri::XSLT(File.read(stylesheet_path))
      stylesheet.transform(doc)
    end
  end
end
