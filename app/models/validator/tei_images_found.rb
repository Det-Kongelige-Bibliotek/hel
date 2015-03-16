module Validator
  class TeiImagesFound

    def validate(record)
      if (record.is_a? Instance) && !record.blank? && record.type == 'TEI'
        cnt = 0
        record.content_files.each do |cf|
          xdoc = Nokogiri::XML.parse(cf.datastreams['content'].content) { |config| config.strict }
          xdoc.xpath("//xmlns:pb").each do |n|
            res = ActiveFedora::SolrService.query("pb_xml_id_tesim:#{n.attr('xml:id')} &&  pb_facs_id_tesim:#{n.attr('facs')}")
            record.errors[:base] << "No image found for #{n.to_s}" if (res.size == 0)
            record.errors[:base] << "More than 1 image found for #{n.to_s}" if (res.size > 1)
          end
        end
      else
        record.errors[:base] << "Not a TEI instance"
      end
    rescue Exception => e
      record.errors[:base] << e.message
    end


  end
end