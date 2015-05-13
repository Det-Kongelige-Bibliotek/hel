require 'fileutils'

# This class should be used to represent
# all content datastreams. File order should
# be given on the Instance level.
class ContentFile < ActiveFedora::Base
  include Hydra::AccessControls::Permissions
  include Concerns::TechMetadata
  include Concerns::Preservation
  include Concerns::FitsCharacterizing
  include Concerns::UUIDGenerator
  include Concerns::CustomValidations

  belongs_to :instance, property: :content_for

  # Adds a content datastream to the object as an external managed file in fedore
  #
  # @param path external url to the firl

  ### custom validations
  ## run through the list of validators in self.validators
  ## check if it is a valid validator and validates the content file with it
  ## example: is it at valid relaxed Tei file
  ## this enables us to dynamically add validation to individual content files
  validate :custom_validations

  def custom_validations
    valid = true
    self.validators.each do |vname|
      v = get_validator_from_classname(vname)
      isOK = v.validate self
      valid = valid && isOK
    end
    valid
  end

  # Adds a content datastream to the object as an external managed file in fedore
  #
  # @param path external url to the file
  def add_external_file(path)
    file_name = Pathname.new(path).basename.to_s
    mime_type = mime_type_from_ext(file_name)

    attrs = {:dsLocation => "file://#{path}", :controlGroup => 'E', :mimeType => mime_type, :prefix=>''}
    ds = ActiveFedora::Datastream.new(inner_object,'content',attrs)

    file_object = File.new(path)
    set_file_timestamps(file_object)
    self.checksum = generate_checksum(file_object)
    self.original_filename = file_name
    self.mime_type = mime_type
    self.size = file_object.size.to_s
    self.file_uuid = UUID.new.generate
    file_object.close
    datastreams['content'] = ds
  end


  # Get the path of the external file
  def external_file_path
    path = nil
    if self.datastreams['content'].controlGroup == 'E'
      path = self.datastreams['content'].dsLocation
      if path.start_with? 'file://'
        path.slice! 'file://'
      end
    end
    path
  end

  # This function checks if the content of an external mannaged file
  # has changed, and updates the tech metadata 
  def update_tech_metadata_for_external_file
    if self.datastreams['content'].controlGroup == 'E'
      path = self.external_file_path
      file_object = File.new(path)
      new_checksum = generate_checksum(file_object)
      logger.debug("#{path} checksums #{self.checksum} #{new_checksum}")
      if (new_checksum != self.checksum)
        set_file_timestamps(file_object)
        self.checksum = new_checksum
        self.size = file_object.size.to_s
        return true
      end
    end
    false
  end

  def update_external_file_content(new_content)
    raise "Only content of external files can be overwritten" unless self.datastreams['content'].controlGroup == 'E'
    raise "Content of this file cannot be updated files" unless self.content_can_be_changed?
    file_location = self.external_file_path
    file_object = File.open(file_location,"w:UTF-8")
    file_object.write(new_content)
    self.update_tech_metadata_for_external_file
    self.save
  end


  # Adds a content datastream to the object and generate techMetadata for the basic_files
  # basic_files may either be File or UploadedFile objects.
  #
  # @param file (ActionDispatch::Http:UploadedFile | File)
  # @param characterize Whether or not to put a characterization job on the queue. Default true.
  def add_file(file, characterize=true)
    if file.class == ActionDispatch::Http::UploadedFile
      file_object = file.tempfile
      file_name = file.original_filename
      mime_type = file.content_type
    elsif file.class == File
      file_object = file
      file_name = Pathname.new(file.path).basename.to_s
      mime_type = mime_type_from_ext(file_name)
    else
      logger.warn "Could not add file #{file.inspect}"
      return false
    end

    self.add_file_datastream(file_object, label:  file_name, mimeType: mime_type, dsid: 'content')
    set_file_timestamps(file_object)
    self.checksum = generate_checksum(file_object)
    self.original_filename = file_name
    self.mime_type = mime_type
    self.size = file.size.to_s
    self.file_uuid = UUID.new.generate
    self.save!
    Resque.enqueue(FitsCharacterizingJob,self.pid) if characterize
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
      when '.txt', '.rdf'
        'text/plain'
      when '.png'
        'image/png'
      else
        raise "no mimetype found for extension #{ext} !"
    end
  end

  ## Model specific preservation functionallity
  def create_preservation_message_metadata
    res = "<provenanceMetadata><fields><uuid>#{self.uuid}</uuid></fields></provenanceMetadata>\n"
    res +="<preservationMetadata>"
    res += self.preservationMetadata.content
    res +="</preservationMetadata>\n"
    res +="<techMetadata>"
    res += self.techMetadata.content
    res +="</techMetadata>\n"
    unless self.fitsMetadata.nil? || self.fitsMetadata.content.nil? || self.fitsMetadata.content.empty?
      res +="<fitsMetadata>"
      res += self.fitsMetadata.content
      res +="</fitsMetadata>\n"
    end
    res
  end

  def can_perform_cascading?
    false
  end

  def content_can_be_changed?
    self.mime_type == 'text/xml'
  end

  def self.find_by_original_filename(fname)
    result = ActiveFedora::SolrService.query('original_filename_tesim:"'+fname+'"')
    if result.size > 0
      ContentFile.find(result[0]['id'])
    else
      nil
    end
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

  def fetch_file_from_url(url)
    logger.debug "Starting GET of file from #{url}"
    start_time = Time.now
    uri = URI.parse(url)
    if (uri.kind_of?(URI::HTTP))
      resp = Net::HTTP.get_response(uri)
      case resp
        when Net::HTTPSuccess then
          filename = File.basename(uri.path)
          tmpfile = Tempfile.new(filename,Dir.tmpdir)
          File.open(tmpfile.path,'wb+') do |f|
            f.write resp.body
          end
          tmpfile.flush
          logger.debug "GET took #{Time.now - start_time} seconds"
          return tmpfile
        else
          logger.error "Could not get file from location #{url} response is #{resp.code}:#{resp.message}"
          return nil
      end
    else
      return nil
    end
  rescue URI::InvalidURIError
    logger.error "Invalid URI #{url}"
    nil
  rescue => e
    logger.error "error in fetch_file_from_url #{url}"
    logger.error e.backtrace.join("\n")
    nil
  end
end
