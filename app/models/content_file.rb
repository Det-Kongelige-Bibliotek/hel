require 'fileutils'

# This class should be used to represent
# all content datastreams. File order should
# be given on the Instance level.
class ContentFile < ActiveFedora::Base
  include Hydra::AccessControls::Permissions
  include Concerns::TechMetadata
  include Concerns::Preservation
  include Concerns::FitsCharacterizing
  include Concerns::CustomValidations

  belongs_to :instance, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf

  contains "fileContent"

  # Adds a content datastream to the object as an external managed file in
  # fedore
  #
  # @param path external url to the firl

  before_save :set_rights_metadata

  ### custom validations
  ## run through the list of validators in self.validators
  ## check if it is a valid validator and validates the content file with it
  ## example: is it at valid relaxed Tei file
  ## this enables us to dynamically add validation to individual content files
  validate :custom_validations

  after_save do
    Resque.enqueue(DisseminateJob,self.instance.id) if self.instance.present? && !self.instance.cannot_be_published?
  end

  def uuid
    self.id
  end

  def custom_validations
    valid = true
    self.validators.each do |vname|
      v = get_validator_from_classname(vname)
      isOK = v.validate self
      valid = valid && isOK
    end
    valid
  end

  def set_rights_metadata
    return unless self.instance && self.instance.activity
    # fail 'No activity' unless self.instance.activity
    a = Administration::Activity.find(self.instance.activity)
    self.discover_groups = a.activity_permissions['file']['group']['discover']
    self.read_groups = a.activity_permissions['file']['group']['read']
    self.edit_groups = a.activity_permissions['file']['group']['edit']
  end


  # Adds a content datastream to the object as an external managed file in fedore
  # Note that this should be an absolute path!
  # @param path external url to the file
  def add_external_file(path)
    file_name = Pathname.new(path).basename.to_s

    self.external_file_path = path
    file_object = File.new(path)
    set_file_timestamps(file_object)
    self.original_filename = file_name
    if File.directory?(file_object)
      mime_type = "inode/directory"
      self.mime_type = mime_type
    else
      self.checksum = generate_checksum(file_object)
      mime_type = MIME::Types.type_for(file_name).first.content_type
      self.mime_type = mime_type
    end
    self.size = file_object.size.to_s
    self.file_uuid = UUID.new.generate
    file_object.close
  end

  def is_external_file?
    self.external_file_path.present?
  end

  def content
    content = nil
    #if the file is external fetch the content of the file and return it
    if self.is_external_file?
      f = File.new(self.external_file_path)
      content = f.read
      f.close
    else
      content = self.fileContent.content if self.fileContent.present?
    end
    content
  end


  # This function checks if the content of an external mannaged file
  # has changed, and updates the tech metadata 
  def update_tech_metadata_for_external_file
    if self.is_external_file?
      path = self.external_file_path
      file_object = File.new(path)
      new_checksum = generate_checksum(file_object)
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
    raise "Only content of external files can be overwritten" unless self.is_external_file?
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
    if file.class == ActionDispatch::Http::UploadedFile || file.class == Rack::Test::UploadedFile
      file_object = file.tempfile
      file_name = file.original_filename
      mime_type = file.content_type
    elsif file.class == File
      file_object = file
      file_name = Pathname.new(file.path).basename.to_s
      if File.directory?(file_object)
        mime_type = "inode/directory"
      else
        # TODO: this could be improved through use of filemagick https://github.com/ricardochimal/ruby-filemagic
        mime_type = MIME::Types.type_for(file_name).first.content_type
      end
    else
      logger.warn "Could not add file #{file.inspect}"
      return false
    end
    self.file_uuid = UUID.new.generate if self.file_uuid.blank?
    self.original_filename = file_name if self.original_filename.blank?

    self.fileContent.content = file_object if File.file?(file_object)
    set_file_timestamps(file_object)
    self.checksum = generate_checksum(file_object) if File.file?(file_object)
    self.mime_type = mime_type
    self.size = file.size.to_s
    self.external_file_path = nil
    if self.save
      Resque.enqueue(FitsCharacterizingJob,self.id) if characterize
      true
    else
      logger.error "Error adding file to ContentFile #{self.errors.messages}"
      false
    end
  end

  ## Model specific preservation functionallity
  def create_preservation_message_metadata
    XML::ContentFileSerializer.preservation_message(self)
  end

  def can_perform_cascading?
    false
  end

  def content_can_be_changed?
    self.mime_type == 'text/xml' || self.mime_type == 'application/xml'
  end

  def self.find_by_original_filename(fname)
    result = ActiveFedora::SolrService.query('original_filename_tesim:"'+fname+'"')
    if result.size > 0
      ContentFile.where(id: result[0]['id']).first
    else
      nil
    end
  end

  def self.find_by_pb_facs_id(id)
    ActiveFedora::SolrService.query('pb_facs_id_tesim:"'+id+'" && has_model_ssim:ContentFile ')
  end

  # Adding instance variables to the SOLR document for improving the search for statistics.
  # TODO: embargo_date should be in date format - though it is currently a string in the instance.
  def to_solr(solr_doc = {})
    solr_doc.merge!(super)
    Solrizer.insert_field(solr_doc, 'activity', instance.activity, :stored_searchable) if instance && instance.activity
    Solrizer.insert_field(solr_doc, 'collection', instance.collection, :stored_searchable) if instance && instance.collection
    Solrizer.insert_field(solr_doc, 'embargo', instance.embargo, :stored_searchable) if instance && instance.embargo
    Solrizer.insert_field(solr_doc, 'embargo_date', instance.embargo_date, :stored_searchable) if instance && instance.embargo_date
    Solrizer.insert_field(solr_doc, 'material_type', instance.material_type, :stored_searchable) if instance && instance.material_type
    Solrizer.insert_field(solr_doc, 'instance_type', instance.type, :stored_searchable) if instance && instance.type
    Solrizer.insert_field(solr_doc, 'instance_id', instance.id, :stored_searchable) if instance && instance.id
    Solrizer.insert_field(solr_doc, 'work_id', instance.work.id, :stored_searchable) if instance && instance.work && instance.work.id
    # Aktivitet
    # Samling
    # Klausulering
    # Materialetype
    # Bevaringsprofil

    solr_doc
  end


  # return checksums for all disseminated versions
  # as a hash, e.g. {'ADL' => 'randomfuckingchecksum'}
  def disseminated_versions
    versions = {}
    dissemination_checksums.each do |csum|
      platform, version = csum.split(':')
      versions[platform] = version
    end
    versions
  end

  # Add a new dissemination checksum
  def add_dissemination_checksum(platform, checksum)
    versions = self.dissemination_checksums.reject {|csum| csum.include? platform}
    versions << "#{platform}:#{checksum}"
    self.dissemination_checksums = versions
  end

  # Handle the import from preservation POST request.
  # @param params The parameters from the POST request.
  # Must contain 'type'='FILE', the token and the file.
  def handle_preservation_import(params)
    # only support content of ContentFile import
    # TODO implement also metadata import
    if(params['type'] != 'FILE')
      logger.warn 'Can only support type = FILE'
      return false
    end

    # Validate that preservation import is allowed
    if self.import_token.blank?
      logger.warn 'No import token, thus no preservation import expected.'
      return false
    end

    # The post request must deliver a token.
    if params['token'].blank?
      logger.warn "No import token delivered. Expected: #{self.import_token.blank?}"
      return false
    end

    if self.import_token != params['token']
      logger.warn "Received import token '#{params['token']}' but expected '#{self.import_token}'"
      return false
    end

    # Validate timeout
    if self.import_token_timeout.to_datetime < DateTime.now
      logger.warn 'Token has timed out and is no longer valid.'
      return false
    end

    # Remove the token, so it cannot be used again.
    self.import_token = ""
    self.save!

    logger.info 'Importing the file from preservation'
    self.add_file(params['file'])
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
