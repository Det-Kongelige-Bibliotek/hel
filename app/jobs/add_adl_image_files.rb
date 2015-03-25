require 'resque'


# Resque job: Given a TEI file add tiff-file to at equivalent TIFF instance for each pb
# param content_file_id: PID of the TEI ContentFile object
# param base_dir: where the tiff files are located on the filesystem
# base_dir should contain a file 'file_list.text' with a list of all the TEI files
# for now we use the filename as 'facs' ID
# TODO: include facs ids in file_list

class AddAdlImageFiles

  @queue = 'add_adl_image_files'

  def self.perform(content_file_id,base_path)

    cf = ContentFile.find(content_file_id)
    xdoc = Nokogiri::XML.parse(cf.datastreams['content'].content) { |config| config.strict }

    # only try to load images for tei files that have pagebreaks
    if xdoc.xpath("//xmlns:pb").size > 0
      tei_inst = cf.instance
      tiff_inst = nil
      if tei_inst.has_equivalent.size > 0
        #TODO: handle case with more than one equivalent instanse
        tiff_inst = tei_inst.has_equivalent.first
      else
        tiff_inst = Instance.new
        # these values should be inherited from the tei_inst
        tiff_inst.activity = tei_inst.activity
        tiff_inst.copyright = tei_inst.copyright
        tiff_inst.collection = tei_inst.collection
        tiff_inst.preservation_profile = tei_inst.preservation_profile
        tiff_inst.type = 'TIFF'
        unless tiff_inst.save
          raise "error creating tiff instance #{tiff_inst.errors.messages}"
        end
        tiff_inst.set_work=tei_inst.work.first
        tei_inst.has_equivalent << tiff_inst
        tei_inst.save
      end

      file_map = load_file_map(File.join(base_path,"file_list.txt"))

      xdoc.xpath("//xmlns:pb").each do |n|
        begin
          Resque.logger.debug("Processing #{n.to_s}")
          xml_id = n.attr('xml:id')
          raise "No xml:id" if xml_id.blank?

          facs = n.attr('facs')
          raise "No facs" if facs.blank?

          file = file_map[facs]

          unless ContentFile.find_by_original_filename(File.basename(file)).blank?
            raise "File #{File.basename(file)} already added .. skipping it"
          end

          Resque.logger.debug("Adding file #{file}")
          tiff_file = tiff_inst.add_file("#{base_path}/#{file}")
          unless tiff_file.errors.blank?
            raise "Unable to add file save errors #{tiff_file.errors.messages}"
          end

          tiff_file.pb_xml_id = xml_id
          tiff_file.pb_facs_id = facs
          unless tiff_file.save
            raise "Unable to save tiff file #{tiff_file.errors.messages}"
          end
        rescue Exception => e
          Resque.logger.error("Unable to add file for pb #{n.to_s}: #{e.message}" )
        end
      end
    else
      Rescue.logger("Content file #{content_file_id} has no tiff files")
    end
  end

  def self.load_file_map(path)
    Resque.logger.debug("opening file list #{path}")
    f = File.open(path)
    result = {}
    f.each_line do |line|
      facs_id = File.basename(line,File.extname(line))
      result[facs_id] = line.chomp
    end
    Resque.logger.debug("got #{result.size} files")
    result
  end
end