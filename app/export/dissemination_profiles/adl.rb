module DisseminationProfiles
  # A Dissemination profile is a class that is
  # responsible for publishing content to a public facing platform.
  # This may be a file server, Solr index etc
  # It must have one method disseminate. This takes an instance as its argument.
  class Adl

    def self.platform
      'ADL'
    end

    def self.disseminate(instance)
      w = instance.work
      raise 'instance has no work' unless w.present?

      if instance.type == 'TEI'
        instance.content_files.each do |cf|
          # check if file content has been altered before updating everything - need a content hash field and method
          # otherwise do nothing
          disseminated_checksum = cf.disseminated_versions[self.platform]
          if disseminated_checksum.nil? || disseminated_checksum != cf.checksum

            Resque.logger.debug "disseminating instance #{instance.id}"

            tei_file_path = cf.external_file_path
            filename = File.basename(tei_file_path,File.extname(tei_file_path))
            vars = build_variable_array(filename,w,instance,get_category(tei_file_path))
            doc = transform(tei_file_path,vars)
            add_to_solr(doc.to_xml)
            if w.authors.present?
              author_xml = generate_person_doc(w.authors.first)
              add_to_solr(author_xml)
            end

            # uncomment the following lines to get solr_docs printed to files
            #File.open("seed_docs/#{filename}.xml", 'w') { |f| f.print(doc.to_xml) }
            #File.open("seed_docs/#{w.authors.first.family_name}_person.xml",'w') {|f| f.print(author_xml)}

            # update exist with REST call
            send_to_exist(tei_file_path)
            # save checksum value so we know what the last version disseminated is
            #cf.add_dissemination_checksum(self.platform, cf.checksum)
            #cf.save
          else
            Rails.logger.info "file #{cf.id} is up to date on platform #{self.platform} skipping dissemination..."
          end
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
      solr = RSolr.connect :url => CONFIG[Rails.env.to_sym][:bifrost_adl_solr_url]
      solr.update(data: solr_doc)
      solr.commit
    end

    def self.transform_and_disseminate(tei_file_path,variables)
      doc = self.transform(tei_file_path,variables)
      self.add_to_solr(doc.to_xml)
    end

    def self.generate_person_doc(author)
      Resque.logger.debug "disseminating author #{author.id}"
      doc = {id: author.id, cat_ssi: 'person', work_title_tesim: author.full_name, author_name: author.full_name,
             family_name_ssi: author.family_name, given_name_ssi: author.given_name,
             birth_date_ssi: author.birth_date, death_date_ssi: author.death_date, type_ssi: 'trunk'}
      RSolr.connect.xml.add(doc,{})
    end

    def self.build_variable_array(filename,work,instance,category)
      vars = []
      vars << 'category'
      vars << "'#{category}'"
      vars << 'file'
      vars << "'#{filename}'"
      # TODO handle multiple authors
      if work.authors.size > 0
        vars << 'author'
        vars << "'#{work.authors.first.full_name.gsub(/'/) {|s| "\\'"}}'"
        vars << 'author_id'
        vars << "'#{work.authors.first.id}'"
      end
      if instance.copyright.present?
        vars << 'copyright'
        vars << "'#{instance.copyright.gsub(/'/) {|s| "\\'"}}'"
      end
      # TODO handle multiple editors
      if work.editors.size > 0
        vars << 'editor'
        vars << "'#{work.editors.first.display_value.gsub(/'/) {|s| "\\'"}}'"
        vars << 'editor_id'
        vars << "'#{work.editors.first.id}'"
      end
      if work.titles.present?
        vars << 'volume_title'
        vars << "'#{work.titles.first.value.gsub(/'/) {|s| "\\'"}}'"
      end
      if instance.publisher_name.present?
        vars << 'publisher'
        vars << "'#{instance.publisher_name.gsub(/'/) {|s| "\\'"}}'"
      end
      if instance.published_date.present?
        vars << 'published_date'
        vars << "'#{instance.published_date}'"
      end
      unless instance.publisher_place.nil?
        vars << 'published_place'
        vars << "'#{instance.publisher_place.join(', ').gsub(/'/) {|s| "\\'"}}'"
      end
      vars << 'uri_base'
      vars << "'http://adl.kb.dk/'"
    end

    # send a put request to exist with the updated file
    def self.send_to_exist(file_path)
      base_url = CONFIG[Rails.env.to_sym][:adl_exist_server]
      username = CONFIG[Rails.env.to_sym][:adl_exist_user]
      password = CONFIG[Rails.env.to_sym][:adl_exist_password]
      port = CONFIG[Rails.env.to_sym][:adl_exist_port]
      fpath = Pathname.new(file_path)
      fname = fpath.basename.to_s
      # dir can be 'texts', 'authors', 'periods' etc.
      dir = fpath.dirname.split.last.to_s
      path = CONFIG[Rails.env.to_sym][:adl_exist_path] % { dir: dir,  filename: fname}
      uri = URI.parse("#{base_url}#{path}")
      http = Net::HTTP.new(uri.host, port)
      request = Net::HTTP::Put.new(uri.request_uri)
      request["Content-Type"] = 'text/xml;charset=UTF-8'
      request.basic_auth username, password unless username.nil?
      request.body = File.open(file_path).read
      res = http.request(request)
      raise "unable to update exists url: #{base_url}#{path} response code #{res.code}" unless res.code == "201"
    end

    def self.get_category(tei_file_path)
      return 'portrait' if tei_file_path.include? "/authors/"
      return 'work'
    end
  end
end
