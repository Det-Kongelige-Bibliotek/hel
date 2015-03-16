require 'resque'

class ValidateAdlTeiInstance

  @queue = 'validate_adl_tei_instance'

  def self.perform(pid)
    i = Instance.find(pid)
    i.validation_message = ['Vent Venligst ...']
    i.save

    raise 'Not a ADL Tei instance' unless i.type=='TEI'

    tei_validator = Validator::RelaxedTei.new
    image_validator = Validator::TeiImagesFound.new

    errors = []

    i.content_files.each do |cf|
      if cf.mime_type == 'text/xml'
        Resque.logger.debug("Performing TEI validate on #{cf.original_filename}")
        tei_validator.validate cf
        if cf.errors.size > 0
          cf.errors.each do |error|
            errors << error.message
          end
        else
          errors << "#{cf.original_filename} er valid TEI"
        end
      else
        errors << "#{cf.original_filename} er ikke en xml fil"
      end
    end
    image_validator.validate i
    if i.errors.size > 0
      i.errors.each do |error|
        errors << error.message
      end
    else
      errors << "Alle Billedfiler fundet"
    end
    i.validation_message = errors
    i.save(validate:false)
  end

end