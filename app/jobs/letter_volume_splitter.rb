class LetterVolumeSplitter

  @queue = :letter_volume_splitter

  # Given a reference to a work
  # and a docx derived xml file, create a Work object
  # for each letter with metadata parsed from
  # the result of the xml transform
  def self.perform(work_pid, xml_pid)
    master_work = Work.find(work_pid)
    xml = ContentFile.find(xml_pid)
    activity = Administration::Activity.find(activity: 'Danmarks Breve').first

    raise "Work with pid #{work_pid} not found!" unless master_work
    raise "ContentFile with pid #{xml_pid} not found!" unless xml
    raise 'Danmarks Breve Activity not found!' unless activity

    self.extract_letters(xml, master_work, activity)
  end


  def self.parse_one(xml_pid)
    xml = ContentFile.find(xml_pid)
    parent_dir = Pathname.new(xml.external_file_path).parent
    tei = Nokogiri::XML(xml.datastreams['content'].content)
    divs = tei.css('text body div')


    # create jpg instance
    # create content files for each jpg
  end

  def self.extract_letters(xml, master_work, activity)
    parent_dir = Pathname.new(xml.external_file_path).parent
    tei = Nokogiri::XML(xml.datastreams['content'].content)
    divs = tei.css('text body div')
    prev = nil
    current_page = nil
    divs.each do |div|
      letter = LetterData.new(div)
      # create work
      work = Work.new
      # create relationship to previous letter
      work.add_preceding(prev) unless prev.nil?
      work.is_part_of = master_work
      work.add_title(value: letter.title)
      matching_author = master_work.find_matching_author(letter.sender_name)
      if matching_author.present?
        work.add_author(matching_author)
      else
        work.add_author(master_work.authors.first)
      end
      fail "Letter could not be saved! #{work.errors.messages}" unless work.save
      Resque.logger.info "Letter saved with id #{work.id}"

      # add TEI reference with id
      xml_instance = Instance.from_activity(activity)
      cf = ContentFile.new
      cf.add_external_file(xml.external_file_path)
      cf.xml_pointer = letter.id
      cf.instance = xml_instance
      cf.save
      xml_instance.work << work
      fail "XML Instance could not be saved! #{xml_instance.errors.messages}" unless xml_instance.save

      # add image references based on pb facs
      jpg_instance = Instance.from_activity(activity)
      jpg_instance.work << work
      letter.image_refs.each do |ref|
        cf = ContentFile.new
        Resque.logger.debug "Parent dir is #{parent_dir}"
        Resque.logger.debug "Facsimile ref is #{ref}"
        file_path = parent_dir.join(ref).to_s
        unless File.exist? file_path
          Resque.logger.error "File #{file_path} not found!"
          next
        end
        cf.add_external_file(file_path)
        cf.instance = jpg_instance
        cf.save
      end
      fail "JPG Instance could not be saved! #{jpg_instance.errors.messages}" unless jpg_instance.save
    end
  end

  # changeme:205

  # Given a tei xml doc, create a work
  # for each letter with a relation to
  # a given master work
  # @param Nokogiri::XML::Document
  # @param Work master_work
  def self.parse_letters(tei, master_work)
    divs = tei.css('text body div')
    start_page_break = tei.css('pb').first.attr('n')
    raise 'First page break does not have n attribute' if start_page_break.nil?
    # file prefix is the volume name, the same as a jpgs name without the last 4 digits and the .jpg
    # file_prefix = master_work.ordered_instance_types[:jpgs].files.first.original_filename.sub(/_\d{4}.jpg/, '')
    # Create Works for each letter with relations
    # to the previous letter and the master work
    prev_letter = nil
    divs.each do |div|
      prev_letter, start_page_break = self.create_letter(div, prev_letter, master_work, start_page_break, file_prefix)
      prev_letter.save
    end
  end

  # Given an xml element representing a
  # TEI div - create a letter work with
  # a relation to the previous work and the
  # master work
  # @param Nokogiri::XML::Element div
  # @param Work prev_letter
  # @param Work master_work
  # @return Work (the new letter), String last_page
  def self.create_letter(div, prev_letter, master_work, first_page, file_prefix)
    data = self.parse_data(div, first_page)
    letter = Work.new
    letter.workType = 'Letter'
    letter.note = [data[:note]] if data[:note]
    letter.dateCreated = data[:date] if data[:date]
    letter.identifier= [{'displayLabel' => 'teiRef', 'value' => data[:id]}] if data[:id]
    letter.activity = 'Brevprojekt'
    letter.workflow_status = 'Ingested'
    if data[:sender_name]
      author = Person.from_string(data[:sender_name])
      letter.hasAuthor << author
    end
    if data[:recipient_name]
      recipient = Person.from_string(data[:recipient_name].strip)
      letter.hasAddressee << recipient
    end
    if data[:sender_address]
      sender_address = Place.create(name: data[:sender_address])
      letter.hasOrigin << sender_address
    end
    file_path = self.save_to_file(data[:id], div)
    inst = SingleFileInstance.new_from_file(File.new(file_path))
    letter.add_instance(inst)
    letter = self.create_jpg_oi(letter, data, file_prefix)
    master_work.add_part(letter)
    letter.add_previous(prev_letter) unless prev_letter.nil?
    letter.save
    File.delete(file_path)
    # we need to return the last page found
    # in order to create the next start page
    [ letter, data[:end_page] ]
  end

  # given a work and a data array containing
  # a start and end page, create an ordered
  # representation representing these files
  #
  def self.create_jpg_oi(work, data, file_prefix)
    pics = OrderedInstance.new(contentType: 'jpg')
    start_page = data[:start_page].to_i
    end_page = data[:end_page].to_i
    (start_page..end_page).each do |num|
      filename = self.create_filename(file_prefix, num.to_s)
      file = BasicFile.find(original_filename_ssi: filename).first
      if file.nil?
        logger.error "Work #{work.pid}: #{filename} not found in index"
        Resque.logger.error "#{filename} not found in index"
      else
        logger.debug "Work #{work.pid}: adding #{filename} to ordered instance"
        pics.files << file
      end
    end
    pics.save
    work.add_instance(pics)
    work
  end

  # Given an id and and a Nokogiri
  # XML element - save the xml to a
  # file named by the id and return a
  # file path
  # @param id String
  # @param xml Nokogiri::XML::Node
  def self.save_to_file(id, xml)
    name = id || "Letter imported " + Time.now.to_s
    name += '.xml'
    file_path = Rails.root.join('tmp', name)
    File.write(file_path, xml.to_xml)
    file_path
  end

  # Given a Nokogiri::XML::Element
  # representing a single div
  # return a hash of metadata parsed from this element
  # @param Nokogiri::XML::Element
  # @return Hash
  def self.parse_data(div, first_page)
    data = Hash.new
    letter = LetterData.new(div)
    data[:id] = letter.id
    data[:num] = letter.num
    data[:date] = letter.date
    data[:body] = letter.body
    data[:sender_name] = letter.sender_name
    data[:recipient_name] = letter.recipient_name
    data[:sender_address] = letter.sender_address
    data[:needs_attention] = letter.needs_attention?
    data[:note] = letter.note
    data[:start_page] = (first_page.to_i + 2).to_s
    # if the div has a pagebreak, endpage is the value
    # of the last pagebreak, otherwise it's the start page
    end_page = div.css('pb').last ? div.css('pb').last.attr('n') : first_page
    data[:end_page] = (end_page.to_i + 2).to_s
    data
  end


  # work out the jpg filename based on the
  # prefix and filenum
  # e.g. "001003574_000", "4" ==>  "001003574_000_0004.jpg"
  # @param String, String
  # @return String
  def self.create_filename(prefix, file_num)
    prefix +  '_' + file_num.rjust(4, '0') + '.jpg'
  end
end

# Helper class to wrap some of the parsing logic
class LetterData

  attr_reader :div

  # @param div (nokogiri element)
  def initialize(div)
    @div = div
    nil
  end

  def id
    @div.attributes['id'].value if @div.attributes['id'].present?
  end

  def num
    @div['n']
  end

  def date
    @div.css('date').first.text if @div.css('date').length > 0
  end

  def page_nums
    page_breaks.collect {|pb| pb['n'] }
  end

  # select all facsimile links from pb elements
  def image_refs
    refs = page_breaks.collect {|pb| pb['facs'] }
    refs.select(&:present?)
  end

  def page_breaks
    @div.css('pb')
  end

  def body
    @div.text
  end

  def note
    if @div.css('note').length > 0
      val = @div.css('note').first.text
      { displayLabel: 'noteFromText', value: val }
    end
  end

  def sender_name
    @div.css('closer signed persName').first.text if @div.css('closer signed persName').length > 0
  end

  def recipient_name
    @div.css('opener salute persName').first.text if @div.css('opener salute persName').length > 0
  end

  def sender_address
    @div.css('opener dateline geogName').first.text if @div.css('opener dateline geogName').length > 0
  end

  def title
    "Brev fra #{if_present(sender_name)} til #{if_present(recipient_name)}, #{if_present(sender_address)} #{if_present(date)}"
  end

  def if_present(string)
    string.present? ? string : 'Ukendt'
  end
end