module Validator
  class TeiImagesFound

    def validate(record)
      if (record.is_a? Instance) && !record.blank?  && (record.type == 'TEI')

        record.content_files.each do |cf|
          xdoc = Nokogiri::XML.parse(cf.content) { |config| config.strict }
          xdoc.xpath("//xmlns:pb").each do |n|
            res = ContentFile.find_by_pb_facs_id(n.attr('facs'))
            record.errors[:base] << "No image found for #{n.to_s}" if (res.size == 0)
            record.errors[:base] << "More than 1 image found for #{n.to_s}" if (res.size > 1)

          end
        end
      end
    end


  end
end