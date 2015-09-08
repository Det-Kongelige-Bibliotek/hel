require 'resque'

class SendRequestToImportFromPreservationJob

  @queue = 'import_from_preservation'

  def self.perform(pid, type=nil, update=nil)
    obj = nil
    begin
      obj = ActiveFedora::Base.find(pid)
    rescue ActiveFedora::ObjectNotFoundError
      raise ArgumentError.new "No object with pid #{pid} found"
    end

    if !obj.respond_to?('initiate_import_from_preservation')
      raise ArgumentError.new "Object #{pid} of type #{obj.class.name} cannot import from preservation"
    end

    if obj.warc_id.blank?
      raise ArgumentError.new "The object #{pid} must have been preserved already and have a 'WARC_ID'."
    end

    # Check for type
    if type.blank? || type != 'FILE'
      raise ArgumentError.new "Import type #{type} cannot be imported. Can only import type 'FILE'"
    end

    obj.initiate_import_from_preservation(type, update)
  end
end
