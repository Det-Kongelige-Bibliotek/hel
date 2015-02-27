require 'resque'

class AddAdlImageFiles

  def self.perform(content_file_id)


    cf = ContentFile.find(content_file_id)
    tei_inst = cf.instance
    tiff_inst = nil
    if tei_inst.has_equivalent.size > 0
      #TODO: handle case with more than one equivalent instanse
      tiff_inst = tei_inst.has_equivalent.first
    else
      tiff_inst = Instance.new
      tiff_inst.activity = tei_inst.activity
      tiff_inst.copyright = tei_inst.copyright
      tiff_inst.collection = tei_inst.collection
      tiff_inst.preservation_profile = tei_inst.preservation_profile
     # tiff_inst.type = 'tiff'
      unless tiff_inst.save
        raise "error creating tiff instance #{tiff_inst.errors.messages}"
      end
      puts ("work is #{tei_inst.work.first.id}")
      tiff_inst.set_work=tei_inst.work.first
      tei_inst.has_equivalent << tiff_inst
      tei_inst.save
    end

    file_map = load_file_map('/tmp/adl_image_files.text')

    xdoc = Nokogiri::XML.parse(cf.datastreams['content'].content) { |config| config.strict }

    xdoc.xpath("//xmlns:pb").each do |n|
      begin
        xml_id = n.attr('xml:id')
        raise "No xml:id" if xml_id.blank?

        facs = n.attr('facs')
        raise "No facs" if facs.blank?

        puts "ref  '#{xml_id}::#{facs}'"

        uri = file_map[facs]
        raise "No uri for facs #{facs}" if uri.blank?

        puts "uri #{uri}"

        Resque.logger.debug("Adding file #{uri}")

        tiff_file = tiff_inst.add_file(uri)
        unless tiff_file.errors.blank?
          raise "Unable to add file save errors #{tiff_file.errors.messages}"
        end

        tiff_file.tei_ref = "#{xml_id}::#{facs}"
        tiff_file.save
      rescue Exception => e
        Resque.logger.error("Unable to add file for pb #{n.to_s}: #{e.message}" )
        puts "Unable to add file for pb #{n.to_s}: #{e.message}"
        pp e
      end
    end
  end

  def self.load_file_map(path)
    f = File.open(path)
    result = {}
    f.each_line do |line|
      facs_id = File.basename(line,File.extname(line))
      result[facs_id] = line.chomp
    end
    result
  end
end