# -*- encoding : utf-8 -*-
module Datastreams
  #This class is designed to reflect the METS 1.9.1 schema with emphasis upon the structMap element used for defining
  #the sequential order in which basic_files appear
  class MetsStructMap < ActiveFedora::OmDatastream

    set_terminology do |t|
      t.root(:path => 'mets', :encoding => 'UTF-8')

      t.structMap do
        t.ordered_file
      end
    end

    define_template :ordered_file do |xml,order,file_id|
      xml.div(:ORDER=>order) do
        xml.fptr(:FILEID=>file_id)
      end
    end

    def add_file(order,file_id)
      structmap = find_by_terms(:structMap).first
      node = add_child_node(structmap,:ordered_file, order,file_id)
      content_will_change!
      node
    end

    def ordered_files
      structMap = find_by_terms(:structMap).first
      result = {}
      structMap.children.each do |div|
        if (div.name == 'div' && !div.attribute('ORDER').blank?)
          order = div.attribute('ORDER').text
          div.children.each do |fptr|
            if (fptr.name == 'fptr' && !fptr.attribute('FILEID').blank?)
              result[order] = fptr.attribute('FILEID').text
            end
          end
        end
      end
      result
    end

    def clear_structMap
      structMap = find_by_terms(:structMap).first
      structMap.children.remove
      content_will_change!
    end


    def self.xml_template
      Nokogiri::XML.parse('<mets><structMap></structMap></mets>')
    end
  end
end