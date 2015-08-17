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

    if ['text/xml','application/xml'].include? cf.mime_type
      xdoc = Nokogiri::XML.parse(cf.content) { |config| config.strict }

      # only try to load images for tei files that have pagebreaks
      if xdoc.xpath("//xmlns:pb").size > 0
        tei_inst = cf.instance
        tiff_inst = nil
        if tei_inst.equivalents.size > 0
          #TODO: handle case with more than one equivalent instanse
          tiff_inst = tei_inst.equivalents.first
        else
          tiff_inst = Instance.new
          # these values should be inherited from the tei_inst
          tiff_inst.activity = tei_inst.activity
          tiff_inst.copyright = tei_inst.copyright
          tiff_inst.collection = tei_inst.collection
          tiff_inst.preservation_profile = tei_inst.preservation_profile
          tiff_inst.type = 'TIFF'
          tiff_inst.set_work=tei_inst.work
          tiff_inst.set_equivalent = tei_inst
          unless tiff_inst.save
            raise "error creating tiff instance #{tiff_inst.errors.messages}"
          end
          tei_inst.set_equivalent = tiff_inst
          tei_inst.save
        end

        xdoc.xpath("//xmlns:pb").each do |n|
          begin
            Resque.logger.debug("Processing #{n.to_s}")
            xml_id = n.attr('xml:id')
            raise "No xml:id" if xml_id.blank?
            xml_id = xml_id.to_s

            facs = n.attr('facs')
            raise "No facs" if facs.blank?
            facs = facs.to_s

            file = "#{facs}.tif"

            Resque.logger.debug("Adding file #{file}")
            unless ContentFile.find_by_original_filename(File.basename(file)).blank?
              raise "File #{File.basename(file)} already added .. skipping it"
            end

            unless File.file?("#{base_path}/#{file}")
              raise "file is missing"
            end

            tiff_file = tiff_inst.add_file("#{base_path}/#{file}")
            unless tiff_file.errors.blank?
              raise "file save errors #{tiff_file.errors.messages}"
            end

            tiff_file.pb_xml_id = xml_id
            tiff_file.pb_facs_id = facs
            unless tiff_file.save
              raise "tiff file save errors #{tiff_file.errors.messages}"
            end
          rescue Exception => e
            Resque.logger.error("Unable to add file for pb #{n.to_s}: #{e.message}" )
          end
        end
        Resque.enqueue(ValidateAdlTeiInstance,tei_inst.id)
      else
        Resque.logger.error("Content file #{content_file_id} has no tiff files")
      end
    else
        Resque.logger.error("Content Content file #{content_file_id} is not an xml file")
    end
  end

end