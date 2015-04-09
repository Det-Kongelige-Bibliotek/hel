class LetterVolumeIngest

  @queue = :letter_volume_ingest

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
    activity = Administration::Activity.first

    instance_tei.work << work
    instance_tei.type = 'TEI'
    instance_tei.activity = activity.pid
    instance_tei.collection = activity.collection
    instance_tei.copyright = activity.copyright
    instance_tei.preservation_profile = activity.preservation_profile

    instance_jpg.work << work
    instance_jpg.type = 'JPG'
    instance_jpg.activity = activity.pid
    instance_jpg.collection = activity.collection
    instance_jpg.copyright = activity.copyright
    instance_jpg.preservation_profile = activity.preservation_profile

    fail "Instance could not be saved #{instance_tei.errors.messages}" unless instance_tei.save
    fail "Instance could not be saved #{instance_jpg.errors.messages}" unless instance_jpg.save

    ingest_tei_file(pathname, instance_tei)
    ingest_jpg_files(pathname, instance_jpg)

  end

  def self.ingest_tei_file(pathname, instance_tei)
    # Find TEI file
    # Create ContentFile object and attach to TEI Instance
    xml_path = pathname.children.select {|c| c.to_s.include?('.xml') }.first.to_s
    fail "No xml file found in directory #{pathname}" if xml_path.nil?
    c = ContentFile.new
    c.add_external_file(xml_path)
    c.instance = instance_tei
    c.save
  end

  def self.ingest_jpg_files(pathname, instance_jpg)
    # Find JPEG files
    # Create ContentFile objects and attach to JPG Instance
    images_path = pathname.children.select {|c| c.directory?}.first
    fail "No subdirectory found in directory #{pathname}" if images_path.nil?
    jpg_paths = images_path.children.select {|c| c.to_s.include?('.jpg') }
    fail "No jpg file found in directory #{images_path}" if jpg_paths.nil?
    jpg_paths.each do |path|
      c_jpg = ContentFile.new
      c_jpg.add_external_file(path.to_s)
      c_jpg.instance = instance_jpg
      c_jpg.save
    end
  end
end
