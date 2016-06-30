require 'pathname'
require 'nokogiri'
require 'redis'

class EmailXMLIngestService

# Extracts metadata from Aid4Mail XML file
# @param export_file_path: path for Aid4Mail XML file
# @param base_dir_path: base directory for files and folders
  def self.email_xml_ingest(export_file_path, base_dir_path)

    xml = Nokogiri::XML(File.open(export_file_path))

    if !xml.errors.empty?
      Rails.logger.error "Error in XML file: #{export_file_path.to_s} - Error was: #{xml.errors.to_s}"
      fail "Error in XML file: #{export_file_path.to_s} - Error was: #{xml.errors.to_s}"
    end

    folders =  xml.css('Folder')

    if folders.blank?
      Rails.logger.error "The XML file #{export_file_path.to_s}  should contain folders"
      fail "The XML file #{export_file_path.to_s}  should contain folders"
    end

    redis = Redis.new

    folders.each do |folder|
      folder_name = folder['Name']

      # Standardize folder path
      folder_name = folder_name.gsub('\\','/')

      messages = folder.css('Message')

      if messages.blank?
        Rails.logger.error "The folders in XML file #{export_file_path.to_s}  should contain messages"
        fail "The folders in XML file #{export_file_path.to_s}  should contain messages"
      end

      messages.each do |message|
        header = message.css('Header')

        if header.blank?
          Rails.logger.error "The messages in XML file #{export_file_path.to_s}  should contain a header"
          fail "The messages in XML file #{export_file_path.to_s}  should contain a header"
        end

        filenamemd5 = message.css('FileNameMD5')

        if filenamemd5.blank?
          Rails.logger.error "The messages in XML file #{export_file_path.to_s}  should contain a file name MD5"
          fail "The messages in XML file #{export_file_path.to_s}  should contain a file name MD5"
        end

        filenamemd5_text = message.css('FileNameMD5').inner_text

        path_key = base_dir_path.to_s + "/" + folder_name.to_s + "/" + filenamemd5_text.to_s

        header_date = header.css('Date').inner_text
        header_fromName = header.css('FromName').inner_text
        header_fromAddr = header.css('FromAddr').inner_text
        header_replyTo = header.css('ReplyTo').inner_text
        header_to = header.css('To').inner_text
        header_cc = header.css('Cc').inner_text
        header_bcc = header.css('Bcc').inner_text
        header_subject = header.css('Subject').inner_text
        header_priority = header.css('Priority').inner_text
        header_flags = header.css('Flags').inner_text
        header_messageId = header.css('MessageId').inner_text
        message_body = message.css('Body').inner_text
        message_attachments = message.css('Attachments').inner_text
        message_attachmentsFullPath = message.css('AttachmentsFullPath').inner_text
        message_attachmentsFileNames = message.css('AttachmentsFileNames').inner_text

        redis.hset(path_key, "date", header_date)
        redis.hset(path_key, "fromName", header_fromName)
        redis.hset(path_key, "fromAddr", header_fromAddr)
        redis.hset(path_key, "replyTo", header_replyTo)
        redis.hset(path_key, "to", header_to)
        redis.hset(path_key, "cc", header_cc)
        redis.hset(path_key, "bcc", header_bcc)
        redis.hset(path_key, "subject", header_subject)
        redis.hset(path_key, "priority", header_priority)
        redis.hset(path_key, "flags", header_flags)
        redis.hset(path_key, "messageId", header_messageId)
        redis.hset(path_key, "body", message_body)
        redis.hset(path_key, "attachments", message_attachments)
        redis.hset(path_key, "attachmentsFullPath", message_attachmentsFullPath)
        redis.hset(path_key, "attachmentsFileNames", message_attachmentsFileNames)

      end
    end
  end
end