class LetterBookIngest

  @queue = :letter_book_ingest

  def self.perform(dir_path)
    # get sysnumber based on path
    pathname = Pathname.new(dir_path)
    sysnum = pathname.basename.to_s.split('_')[0]

    # get metadata from Aleph

    mods = ConversionService.aleph_to_mods('sys', sysnum)

    # make a letter_book

    lb = LetterBook.new_letterbook({},{})

    lb.save

    instance_tei = lb.get_instance("TEI")
    instance_img = lb.get_instance("TIFF")

    lb.from_mods(mods)
    instance_tei.from_mods(mods)
    instance_tif.from_mods(mods)

    # create Valhal objects
    fail "Work could not be saved #{work.errors.messages}" unless work.save
    # create tei and img instances
    activity = Administration::Activity.where(activity: 'Danmarks Breve').first
    fail 'Activity Danmarks Breve not defined!' unless activity.present?

    instance_tei.activity   = activity.id
    instance_tei.collection = activity.collection
    instance_tei.copyright  = activity.copyright
    instance_tei.preservation_collection = activity.preservation_collection

    instance_img.activity   = activity.id
    instance_img.collection = activity.collection
    instance_img.copyright  = activity.copyright
    instance_img.preservation_collection = activity.preservation_collection

    fail "Instance could not be saved #{instance_tei.errors.messages}" unless instance_tei.save
    fail "Instance could not be saved #{instance_img.errors.messages}" unless instance_img.save

    lb.add_tei_file(pathname)

    tei_id = ingest_tei_file(pathname, instance_tei)

    ingest_img_files(pathname, instance_img)

    Resque.logger.info "Letter Book #{pathname.basename.to_s} imported with id #{work.id}"
#    Resque.enqueue(LetterBookSplitter, work.id, tei_id)
  end

 

  # Find JPEG files
  # Create ContentFile objects and attach to JPG Instance
  def self.ingest_img_files(pathname, instance_img)
    images_path = pathname.children.select {|c| c.directory?}.first
    fail "No subdirectory found in directory #{pathname}" if images_path.nil?
    img_paths = images_path.children.select {|c| c.to_s.include?('.jpg') }
    fail "No jpg file found in directory #{images_path}" if jpg_paths.nil?
    img_paths.each do |path|
      c_img = ContentFile.new
      c_img.add_external_file(path.expand_path.to_s)
      c_img.instance = instance_img
      c_img.save
    end
  end
end
