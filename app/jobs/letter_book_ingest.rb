class LetterBookIngest

  @queue = :letter_book_ingest

  def self.perform(dir_path)
    # get sysnumber based on path
    pathname = Pathname.new(dir_path)
    sysnum = pathname.basename.to_s.split('_')[0]

    # get metadata from Aleph
    work = ConversionService.work_from_aleph('sys', sysnum)
    instance_tei = ConversionService.instance_from_aleph('sys', sysnum)
    instance_jpg = ConversionService.instance_from_aleph('sys', sysnum)

    # create Valhal objects
    fail "Work could not be saved #{work.errors.messages}" unless work.save
    # create TEI and JPG instances
    activity = Administration::Activity.where(activity: 'Danmarks Breve').first
    fail 'Activity Danmarks Breve not defined!' unless activity.present?


    instance_tei.work = work
    instance_tei.type = 'TEI'
    instance_tei.activity = activity.id
    instance_tei.collection = activity.collection
    instance_tei.copyright = activity.copyright
    instance_tei.preservation_collection = activity.preservation_collection

    instance_jpg.work = work
    instance_jpg.type = 'JPG'
    instance_jpg.activity = activity.id
    instance_jpg.collection = activity.collection
    instance_jpg.copyright = activity.copyright
    instance_jpg.preservation_collection = activity.preservation_collection

    fail "Instance could not be saved #{instance_tei.errors.messages}" unless instance_tei.save
    fail "Instance could not be saved #{instance_jpg.errors.messages}" unless instance_jpg.save

    tei_id = ingest_tei_file(pathname, instance_tei)
    ingest_jpg_files(pathname, instance_jpg)
    Resque.logger.info "Letter Book #{pathname.basename.to_s} imported with id #{work.id}"
#    Resque.enqueue(LetterBookSplitter, work.id, tei_id)
  end

  # Find TEI file
  # Create ContentFile object and attach to TEI Instance
  def self.ingest_tei_file(pathname, instance_tei)
    xml_path = pathname.children.select {|c| c.to_s.include?('.xml') }.first
    fail "No xml file found in directory #{pathname}" if xml_path.nil?
    abs_path = xml_path.expand_path.to_s
    c = ContentFile.new
    c.add_external_file(abs_path)
    c.instance = instance_tei
    fail "TEI file could not be saved! #{c.errors.messages}" unless c.save
    c.id
  end

  # Find JPEG files
  # Create ContentFile objects and attach to JPG Instance
  def self.ingest_jpg_files(pathname, instance_jpg)
    images_path = pathname.children.select {|c| c.directory?}.first
    fail "No subdirectory found in directory #{pathname}" if images_path.nil?
    jpg_paths = images_path.children.select {|c| c.to_s.include?('.jpg') }
    fail "No jpg file found in directory #{images_path}" if jpg_paths.nil?
    jpg_paths.each do |path|
      c_jpg = ContentFile.new
      c_jpg.add_external_file(path.expand_path.to_s)
      c_jpg.instance = instance_jpg
      c_jpg.save
    end
  end
end
