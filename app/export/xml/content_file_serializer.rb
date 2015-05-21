module XML
  class ContentFileSerializer

    def self.preservation_message(file)
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.metadata do

          xml.provenanceMetadata do
            xml.fields do
              xml.uuid(file.uuid)
            end
          end
          xml.preservationMetadata do
            xml.parent << file.preservationMetadata.content
          end

          xml.techMetadata do
            xml.parent << file.techMetadata.content
          end

          unless file.fitsMetadata.nil? || file.fitsMetadata.content.nil? || file.fitsMetadata.content.empty?
            xml.fitsMetadata do
              xml.parent << file.fitsMetadata.content
            end
          end
        end
      end

      builder.to_xml
    end

  end
end
