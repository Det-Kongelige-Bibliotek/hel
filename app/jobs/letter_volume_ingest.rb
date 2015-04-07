class LetterVolumeIngest
  include WorkHelper

  @queue = :letter_volume_ingest
  
  def self.perform(xml_path, pdf_path, jpg_path)
    pdf_file = LetterVolumeFile.new(pdf_path)
    xml_file = LetterVolumeFile.new(xml_path)

    unless pdf_file.sysnum == xml_file.sysnum
      raise 'File names do not match!'
    end
    # Check to see if book exists
    work = self.find_or_create_work(pdf_file.sysnum)

    # Check to see if book has an ordered instance
    # corresponding to the necessary contentTypes
    # if not, create new ones
    content_types = work.ordered_instance_types
    pdfs = content_types[:pdfs] || OrderedInstance.new(contentType: 'pdf')
    xmls = content_types[:teis] || OrderedInstance.new(contentType: 'tei')
    jpgs = content_types[:jpgs] || OrderedInstance.new(contentType: 'jpg')

    # Add files to Basic Files
    # add these to instances
    # and add instances to the Work


    bf_pdf = BasicFile.new
    bf_pdf.add_file(File.new(pdf_path), true)
    pdfs.files << bf_pdf
    pdfs.save

    create_structmap(pdfs)


    bf_xml = BasicFile.new
    tmp_file_path = self.transform(xml_path)
    bf_xml.add_file(File.new(tmp_file_path), true)
    File.delete(tmp_file_path) # get rid of temp file
    xmls.files << bf_xml
    xmls.save
    create_structmap(xmls)

    pdfs_saved = work.add_instance(pdfs)
    xmls_saved = work.add_instance(xmls)

    jpgs_array = self.fetch_jpgs(jpg_path)
    jpgs_array.each do |jpg|
      bf_jpg = BasicFile.new
      bf_jpg.add_file(File.new(jpg), true)
      jpgs.files << bf_jpg
    end
    jpgs.save

    create_structmap(jpgs)
    jpgs_saved = work.add_instance(jpgs)

    unless pdfs_saved && xmls_saved && jpgs_saved
      raise 'Could not save to Fedora!'
    end
    Resque.logger.info "Work #{work.pid} saved with filetypes #{work.ordered_instance_types.keys.to_s}"
    Resque.enqueue(LetterVolumeSplitter, work.pid, bf_xml.pid)
  end

  # Given a path to a DOCXML,
  # perform an XSLT transform on it.
  # @param File
  # @return File
  def self.transform(path)
    doc = Nokogiri::XML(File.open(path))
    xslt = File.read(Rails.root.join('xslt', 'docx2tei.xsl').to_s)
    xslt = Nokogiri::XSLT(xslt)
    content = xslt.transform(doc)
    tmp_name = Rails.root.join('tmp', "transformed_" + Pathname.new(path).basename.to_s)
    File.open(tmp_name, 'w') { |f| f << content.to_xml }

    tmp_name
  end

  def self.fetch_jpgs(path_string)
    jpgs = []
    dir = Pathname.new(path_string)
    dir.each_child do |entry_path|
      if entry_path.basename.to_s[-4..-1] == '.jpg'
        jpgs << entry_path.to_s
      end
    end
    jpgs
  end

  # Based on an Aleph sysnum, check to see if work
  # already exists in Aleph and if not, create a new
  # one based on the metadata retrieved from Aleph
  # @param sysnum
  # @return Work, Hash instance metadata
  def self.find_or_create_work(sysnum)
    existing = Work.find('sysnum_si' => sysnum)
    if existing.size > 0
      w = existing.first
      Resque.logger.debug "existing work found with PID #{w.pid}"
      return w
    else
      w = Work.new
      w.identifier=([{'displayLabel' => 'sysnum', 'value' => sysnum }])
      fields = { workType: 'Book', activity: 'Brevprojekt', workflow_status: 'Ingested' }
      # try and get aleph data - will throw error if sysnum not found
      begin
        w = self.add_author_relation(w)
        work, instance_meta, work_meta = ConversionService.aleph_to_valhal(sysnum)
        fields.merge!(work).merge!(work_meta)
      rescue => e
        Resque.logger.debug e.message
      ensure
        w.update(fields)
      end
      # build the work with the data we have retrieved
      w = self.add_work_instances(w, instance_meta)
      Resque.logger.debug "no matching work found - work created with PID #{w.pid}"
      return w
    end
  end

  def self.add_author_relation(work)
    mods = ConversionService.aleph_to_mods_datastream(work.sysnum)
    authors = mods.primary.name
    authors.each do |author|
      p = Person.from_string(author.strip)
      work.hasAuthor << p
      work.save
    end
    work
  end
  # Add OrderedInstances to the work with content type and whatever
  # data we've gotten back from Aleph
  # @param Work
  # @param Hash
  # @return Work
  def self.add_work_instances(work, metadata)
    metadata = {} unless metadata.class == Hash
    work.add_instance(OrderedInstance.new({contentType: 'pdf'}.merge(metadata)))
    work.add_instance(OrderedInstance.new({contentType: 'tei'}.merge(metadata)))
    work.add_instance(OrderedInstance.new({contentType: 'jpg'}.merge(metadata)))
    work
  end

  def self.create_structmap(instance)
    filenames = []
    instance.files.each do |f|
      filenames << f.original_filename
    end
    WorkHelper.create_structmap_for_instance(filenames.sort().join(','),instance)
  end
end

# Helper class to give some useful
# functionality for handling file imports
# for BreveProjektet. It has no relation to Work
# or any other such Data Model classes, it
# is pure BreveProjekt business logic.
# Do not subclass or use in other contexts!!!
class LetterVolumeFile
  def initialize(path_string)
    @file_name = Pathname.new(path_string).basename.to_s
    @file = File.new(path_string)

    raise "invalid filename given: #{file_name}" unless @file_name.include?('_')
  end

  def sysnum
    @file_name.split('_').first
  end

  # if filename ends with underscore X number,
  # then this is a multivolume file
  def multivolume?
    @file_name.split('_').last[0].downcase == 'x'
  end

  # convert the last part of the filename to
  # an integer e.g. '0098372_X01.pdf'=> 1
  def number
    @file_name.split('_').last[1..-1].to_i
  end

  def filename
    @file_name
  end

  def index
    number - 1
  end

end