module Validator

  class Xml < ActiveModel::Validator
    @schema_file = ""

    def validate(record)
      return is_valid record
    end

    def set_schema(schema)
      @schema_file = schema
    end

    def get_schema()
      return @schema
    end

    def schema_selector(file_name)
      file = File.new(file_name)
      ext =  File.extname(file_name)
      case ext
      when '.xsd'
        return Nokogiri::XML::Schema(open(file).read)
      when '.rng'
        return Nokogiri::XML::RelaxNG(open(file).read)
      else
        raise "XML schema language #{ext} is not supported!"
      end
    end
    
    def is_valid(record)
      unless ['text/xml','application/xml'].include? record.mime_type
        record.errors[:base] << "This object is not XML"
      else
        errors = is_valid_xml_content(record.content)
        unless (errors.blank?)
          record.errors[:base] << errors
          return false
        end
        true
      end
    end

    def is_valid_xml_content(content)
      msg = ""
      begin
        if content.nil?
          msg = msg + "Content is nil"
        else
          xdoc = Nokogiri::XML.parse(content) { |config| config.strict }
          msg = is_valid_xml_doc(xdoc)
        end
      rescue Exception => wellformedness
        msg = "XML not wellformed #{wellformedness.message}"
      end
      msg
    end

    def is_valid_xml_doc(xdoc)
      msg = ""
      xval = schema_selector(@schema_file)
      xval.validate(xdoc).each do |error|
        msg += "line: #{error.line} - #{error.message} \n"
      end
      msg
    end

  end
end
