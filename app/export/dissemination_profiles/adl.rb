module DisseminationProfiles
  # A Dissemination profile is a class that is
  # responsible for publishing content to a public facing platform.
  # This may be a file server, Solr index etc
  # It must have one method disseminate. This takes an instance as its argument.
  class Adl
    def self.disseminate(instance)
      puts "disseminating #{instance.id}"
      w = instance.work
      raise 'instance has no work' unless w.present?

      if instance.type == 'TEI'
        instance.content_files.each do |cf|
          tei_file_path = cf.external_file_path
          filename = File.basename(tei_file_path,File.extname(tei_file_path))
          vars = build_variable_array(filename,w,instance)
          doc = transform(tei_file_path,vars)
          author_xml = generate_person_doc(w.authors.first) if w.authors.present?
          # uncomment the following lines to get solr_docs printed to files
          #File.open("seed_docs/#{filename}.xml", 'w') { |f| f.print(doc.to_xml) }
          #File.open("seed_docs/#{w.authors.first.family_name}_person.xml",'w') {|f| f.print(author_xml)}
          add_to_solr(doc.to_xml)
          add_to_solr(author_xml)
        end
      end

      if instance.type == 'TIFF'
        # TODO convert TIFF to JPG2000
      end

    end

    # Given a path to a TEI file, call the XSLT
    # script on it
    def self.transform(tei_file_path,variables)
      doc = Nokogiri::XML(File.read(tei_file_path))
      stylesheet_path = Rails.root.join('app', 'export', 'transforms', 'adder.xsl')
      stylesheet = Nokogiri::XSLT(File.read(stylesheet_path))
      stylesheet.transform(doc, variables) #
    end

    # Given a solr doc in XML string, add to solr index
    def self.add_to_solr(solr_doc)
      #solr = RSolr.connect :url => CONFIG[Rails.env.to_sym][:adl_bifrost_solr_url]
      solr = RSolr.connect :url => 'http://localhost:8984/solr/blacklight-core'
      solr.update(data: solr_doc)
      solr.commit
    end

    def self.transform_and_disseminate(tei_file_path,variables)
      doc = self.transform(tei_file_path,variables)
      self.add_to_solr(doc.to_xml)
    end

    def self.generate_person_doc(author)
      puts "disseminating author #{author.id}"
      doc = {id: author.id, cat_ssi: 'person', work_title_tesim: author.full_name, author_name: author.full_name, birth_date_ssi: author.birth_date, death_date_ssi: author.death_date, type_ssi: 'trunk'}
      RSolr.connect.xml.add(doc,{})
    end

    def self.build_variable_array(filename,work,instance)
      vars = []
      vars << 'file'
      vars << "'#{filename}'"
      # TODO handle multiple authors
      if work.authors.size > 0
        vars << 'author'
        vars << "'#{work.authors.first.full_name}'"
        vars << 'author_id'
        vars << "'#{work.authors.first.id}'"
      end
      if instance.copyright.present?
        vars << 'copyright'
        vars << "'#{instance.copyright}'"
      end
      # TODO handle multiple editors
      if work.editors.size > 0
        vars << 'editor'
        vars << "'#{work.editors.first.display_value}'"
        vars << 'editor_id'
        vars << "'#{work.editors.first.id}'"
      end
      vars << 'volume_title'
      vars << "'#{work.titles.first.value}'"
      vars << 'publisher'
      vars << "'#{instance.publisher_name}'"
      vars << 'published_date'
      vars << "'#{instance.published_date}'"
      vars << 'published_place'
      vars << "'#{instance.publisher_place}'"
      vars << 'uri_base'
      vars << "'http://adl.kb.dk/'"
    end
  end
end
