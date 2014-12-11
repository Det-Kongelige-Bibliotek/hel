require 'fileutils'

# This class should be used to represent
# all content datastreams. File order should
# be given on the Instance level.
class ContentFile < ActiveFedora::Base
  include Hydra::AccessControls::Permissions
  include Concerns::TechMetadata
  include Concerns::Preservation
  include Concerns::UUIDGenerator

  belongs_to :instance, property: :content_for

  # Adds a content datastream to the object and generate techMetadata for the basic_files
  # basic_files may either be File or UploadedFile objects.
  #
  # @param file (ActionDispatch::Http:UploadedFile | File)
  # @param skip_fits boolean
  def add_file(file)
    if file.class == ActionDispatch::Http::UploadedFile
      file_object = file.tempfile
      file_name = file.original_filename
      mime_type = file.content_type
    elsif file.class == File
      file_object = file
      file_name = Pathname.new(file.path).basename.to_s
      mime_type = mime_type_from_ext(file_name)
    else
      return false
    end

    self.add_file_datastream(file_object, label:  file_name, mimeType: mime_type, dsid: 'content')
    set_file_timestamps(file_object)
    self.checksum = generate_checksum(file_object)
    self.original_filename = file_name
    self.mime_type = mime_type
    self.size = file.size.to_s
    self.file_uuid = UUID.new.generate
    true
  end

  def mime_type_from_ext(file_name)
    ext =  File.extname(file_name)
    case ext
      when '.pdf'
        'application/pdf'
      when '.xml'
        'text/xml'
      when '.tif', '.tiff'
        'image/tiff'
      when '.jpg', '.jpeg'
        'image/jpeg'
      when '.txt'
        'text/plain'
      else
        raise "no mimetype found for extension #{ext}!"
    end
  end

  # Extracts the timestamps from the file and inserts them into the technical metadata.
  # @param file The file to extract the timestamps of.
  def set_file_timestamps(file)
    self.created = file.ctime.to_s
    self.last_accessed = file.atime.to_s
    self.last_modified = file.mtime.to_s
  end


  ## Model specific preservation functionallity
  def create_preservation_message_metadata

    res = "<provenanceMetadata><fields><uuid>#{self.uuid}</uuid></fields></provenanceMetadata>"
    res +="<preservationMetadata>"
    res += self.preservationMetadata.content
    res +="</preservationMetadata>"
    res +="<techMetadata>"
    res += self.techMetadata.content
    res +="</techMetadata>"
  end

  def can_perform_cascading?
    false
  end

  private
  def generate_checksum(file)
    Digest::MD5.file(file).hexdigest
  end

  # Extracts the timestamps from the file and inserts them into the technical metadata.
  # @param file The file to extract the timestamps of.
  def set_file_timestamps(file)
    self.created = file.ctime.to_s
    self.last_accessed = file.atime.to_s
    self.last_modified = file.mtime.to_s
  end

end
