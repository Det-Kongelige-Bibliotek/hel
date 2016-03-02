class LetterBookIngest

  @queue = :letter_book_ingest

  def self.perform(xml_file,img_path)
    # get sysnumber based on path
    xml_pathname = Pathname.new(xml_file)
    img_pathname = Pathname.new(img_path)
    sysnum = xml_pathname.basename.to_s.split('_')[0]


    self.send_to_exist(sysnum,xml_pathname)

    self.create_letterbook(sysnum,xml_pathname,img_pathname)

  end

  def self.send_to_exist(sysno,xml_pathname)
    url = "#{SnippetServer.snippet_server_url}/#{sysno}/#{xml_pathname.basename}"
    doc = Nokogiri::XML(File.read(xml_pathname))
    stylesheet_path = Rails.root.join('app', 'export','letters', 'transforms', 'preprocess.xsl')
    stylesheet = Nokogiri::XSLT(File.read(stylesheet_path))
    transformed_doc = stylesheet.transform(doc, {})
    SnippetServer.put(url,transformed_doc.root.to_xml)
  end

  def self.create_letterbook (sysnum,xml_pathname,img_pathname)

    # get metadata from Aleph

    mods = ConversionService.aleph_to_mods('sys', sysnum)

    # make a letter_book

    lb = LetterBook.new_letterbook({},{})

    lb.save

    instance_tei = lb.get_instance("TEI")
    instance_img = lb.get_instance("TIFF")

    lb.from_mods(mods)
    instance_tei.from_mods(mods)
    instance_img.from_mods(mods)

    # create Valhal objects 

    activity = Administration::Activity.where(activity: 'Danmarks Breve').first
    fail 'Activity Danmarks Breve not defined!' unless activity.present?

    instance_tei.activity   = activity.id
    instance_tei.collection = activity.collection
    instance_tei.copyright  = activity.copyright
    instance_tei.preservation_collection = activity.preservation_collection
    instance_tei.status = 'ready'

    instance_img.activity   = activity.id
    instance_img.collection = activity.collection
    instance_img.copyright  = activity.copyright
    instance_img.preservation_collection = activity.preservation_collection
    instance_tei.status = 'ready'

    fail "Work could not be saved #{lb.errors.messages}" unless lb.save 
    fail "Instance could not be saved #{instance_tei.errors.messages}" unless instance_tei.save
    fail "Instance could not be saved #{instance_img.errors.messages}" unless instance_img.save

    puts "adding tei file #{xml_pathname.to_s}"

    lb.add_tei_file(xml_pathname.to_s)
    lb.reload

    puts "lb created #{lb.id}"

    ingest_img_files(img_pathname, instance_img)

    puts "file_id #{lb.get_file_name}"

    solr_doc = SnippetServer.solrize({doc: lb.get_file_name, c: "/db/letter_books/#{sysnum}", work_id: lb.id})
    solr = RSolr.connect
    solr.update(data: '<?xml version="1.0" encoding="UTF-8"?>'+solr_doc)
    solr.commit

    lb.id
  end

 

  # Find JPEG files
  # Create ContentFile objects and attach to JPG Instance
  def self.ingest_img_files(pathname, instance_img)
    img_paths = pathname.children.select {|c| c.to_s.include?('.jpg') }
    fail "No jpg file found in directory #{images_path}" if img_paths.nil?
    img_paths.each do |path|
      c_img = ContentFile.new
      c_img.add_external_file(path.expand_path.to_s)
      c_img.instance = instance_img
      c_img.save
    end
  end
end
