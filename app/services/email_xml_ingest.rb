require 'resque'
require 'pathname'
require 'nokogiri'

class EmailXMLIngest

# Extracts metadata from Aid4Mail XML file
# @param export_file_path: path for Aid4Mail XML file
# @param base_dir_path: base directory for files and folders
  def self.email_xml_ingest(export_file_path, base_dir_path)

    # Has to add XML root tag as Aid4Mail wouldn't do that.
    root_tag_begin = '<Account>'
    root_tag_end = '</Account>'

    File.open(export_file_path, 'r+') do |f|
      str = f.read
      if !str.include? root_tag_begin
        xml_header = str[/<\?xml.*\?>/]
        xml_header_size = xml_header.size
        str.insert(xml_header_size, "\n" + root_tag_begin)
        str.insert(-1, root_tag_end)
      end
      f.rewind
      f.write(str)
    end

    xml = Nokogiri::XML(File.open(export_file_path))

    if !xml.errors.empty?
      Resque.logger.error "Error in XML file: #{export_file_path.to_s} - Error was: #{xml.errors.to_s}"
      fail "Error in XML file: #{export_file_path.to_s} - Error was: #{xml.errors.to_s}"
    end

    folders =  xml.css('Folder')

    if folders.blank?
      Resque.logger.error "The XML file #{export_file_path.to_s}  should contain folders"
      fail "The XML file #{export_file_path.to_s}  should contain folders"
    end

    email_metadata = Hash.new

    folders.each do |folder|
      folder_name = folder['Name']

      # Standardize folder path
      folder_name = folder_name.gsub('\\','/')

      messages = folder.css('Message')

      if messages.blank?
        Resque.logger.error "The folders in XML file #{export_file_path.to_s}  should contain messages"
        fail "The folders in XML file #{export_file_path.to_s}  should contain messages"
      end

      messages.each do |message|
        header = message.css('Header')

        if header.blank?
          Resque.logger.error "The messages in XML file #{export_file_path.to_s}  should contain a header"
          fail "The messages in XML file #{export_file_path.to_s}  should contain a header"
        end

        filenamemd5 = message.css('FileNameMD5')

        if filenamemd5.blank?
          Resque.logger.error "The messages in XML file #{export_file_path.to_s}  should contain a file name MD5"
          fail "The messages in XML file #{export_file_path.to_s}  should contain a file name MD5"
        end

        filenamemd5_text = message.css('FileNameMD5').inner_text

        path_key = base_dir_path.to_s + "/" + folder_name.to_s + "/" + filenamemd5_text.to_s

        # Here good style would be to use symbols as keys instead of strings, however Resque and its JSON serialization
        # of parameters do not take kindly to symbols.
        email_metadata.merge! ({
                                  path_key => {
                                      "date" => header.css('Date').inner_text,
                                      "fromName" => header.css('FromName').inner_text,
                                      "fromAddr" => header.css('FromAddr').inner_text,
                                      "replyTo" => header.css('ReplyTo').inner_text,
                                      "to" => header.css('To').inner_text,
                                      "cc" => header.css('Cc').inner_text,
                                      "bcc" => header.css('Bcc').inner_text,
                                      "subject" => header.css('Subject').inner_text,
                                      "priority" => header.css('Priority').inner_text,
                                      "flags" => header.css('Flags').inner_text,
                                      "messageId" => header.css('MessageId').inner_text,
                                      "body" => message.css('Body').inner_text,
                                      "attachments" => message.css('Attachments').inner_text

                                  }
                              })
      end
    end
    return email_metadata
  end
end
