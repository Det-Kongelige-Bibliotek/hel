class LetterVolumeSplitter

  @queue = :letter_volume_splitter

  # Given a reference to a work
  # and a docx derived xml file, create a Work object
  # for each letter with metadata parsed from
  # the result of the xml transform
  def self.perform(work_pid, xml_pid)
    master_work = Work.find(work_pid)
    xml = ContentFile.find(xml_pid)
    activity = Administration::Activity.where(activity: 'Danmarks Breve').first

    raise "Work with pid #{work_pid} not found!" unless master_work
    raise "ContentFile with pid #{xml_pid} not found!" unless xml
    raise 'Danmarks Breve Activity not found!' unless activity

    self.extract_letters(xml, master_work, activity)
    # update all objects in Solr to ensure index is correct
    Resque.enqueue(UpdateIndex)
  end

  def self.extract_letters(xml, master_work, activity)
    parent_dir = Pathname.new(xml.external_file_path).parent
    tei = Nokogiri::XML(xml.datastreams['content'].content)
    divs = tei.css('text body div')
    pb = tei.css('pb')
    # array with all the image refs of the TEI file
    all_image_refs = pb.collect {|pb| pb['facs'] }
    previous_work = nil
    last_img_ref = nil
    divs.each do |div|
      letter = LetterData.new(div)
      # create work
      work = Work.new
      # create relationship to previous letter
      work.add_preceding(previous_work) unless previous_work.nil?
      work.add_title(value: letter.title)
      work.add_language(letter.language) if letter.language.present?

      # Using the names from the master work, attempt a *best guess*
      # to find the name of tha author and the recipient
      matching_author = master_work.find_matching_author(letter.sender_name)
      matching_recipient = master_work.find_matching_author(letter.recipient_name)
      if matching_author.present?
        work.add_author(matching_author)
      else
        work.add_author(master_work.authors.first)
      end
      if matching_recipient.present?
        work.add_recipient(matching_recipient)
      end

      fail "Letter could not be saved! #{work.errors.messages}" unless work.save
      Resque.logger.info "Letter saved with id #{work.id}"
      master_work.parts << work
      master_work.save

      # add TEI reference with id
      xml_instance = Instance.from_activity(activity)
      xml_instance.type = 'TEI'
      cf = ContentFile.new
      cf.add_external_file(xml.external_file_path)
      cf.xml_pointer = letter.id
      cf.instance = xml_instance
      cf.save
      xml_instance.work << work
      fail "XML Instance could not be saved! #{xml_instance.errors.messages}" unless xml_instance.save

      # add image references based on pb facs
      jpg_instance = Instance.from_activity(activity)
      jpg_instance.type = 'JPEG'
      jpg_instance.work << work

      # if the letter starts before its first <pb> - include the previous pb image
      if letter.preceding_page_break? && last_img_ref.present?
        current_ref_pos = all_image_refs.index(letter.image_refs.first)
        prev_img_ref = all_image_refs[current_ref_pos -1]
        if prev_img_ref.present?
          cf = ContentFile.new
          file_path = parent_dir.join(prev_img_ref).to_s
          Resque.logger.debug "Adding preceding file #{file_path}"
          cf.add_external_file(file_path)
          cf.instance = jpg_instance
          cf.save
        end
      end
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
      last_img_ref = letter.image_refs.last
      previous_work = work
      fail "JPG Instance could not be saved! #{jpg_instance.errors.messages}" unless jpg_instance.save
    end
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

  def language
    @div.attributes['lang'].value if @div.attributes['lang'].present?
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

  # we assume that there is a preceding page break
  # if the position of the first page break is AFTER
  # the position of the first word - i.e. some content
  # MUST be on a previous page break
  def preceding_page_break?
    first_word = @div.text.scan(/\w+/).first
    first_word_pos = @div.to_xml.index(first_word)
    first_pb_pos = @div.to_xml.index('<pb')
    first_pb_pos > first_word_pos rescue nil
  end
end