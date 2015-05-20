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
          xml.preservationMetadata(file.preservationMetadata.content)

          xml.techMetadata(file.techMetadata.content)

          unless file.fitsMetadata.nil? || file.fitsMetadata.content.nil? || file.fitsMetadata.content.empty?
            xml.fitsMetadata(file.fitsMetadata.content)
          end

        end
      end

      builder.to_xml
    end

  end
end
