require 'resque'

class ValidateAdlTeiInstance

  @queue = 'validate_adl_tei_instance'

  def self.perform(pid)
    i = Instance.find(pid)
    i.validation_message = ['Vent Venligst ...']
    i.validation_status = 'INPROGRESS'
    i.save(validate:false)
    i.validation_status = 'VALID'

    raise 'Not a ADL Tei instance' unless i.type=='TEI'

    tei_validator = Validator::RelaxedTei.new
    image_validator = Validator::TeiImagesFound.new

    errors = []

    i.content_files.each do |cf|
      if (cf.mime_type == 'text/xml' || cf.mime_type == 'application/xml')
        Resque.logger.debug("Performing TEI validate on #{cf.original_filename}")
        tei_validator.validate cf
        if cf.errors.size > 0
          i.validation_status = 'INVALID'
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
    Resque.logger.debug("Performing image validate")
    image_validator.validate i
    if i.errors[:base].size > 0
      i.validation_status = 'INVALID'
      i.errors[:base].each do |error|
        errors << error
      end
    else
      errors << "Alle Billedfiler fundet"
    end
    i.validation_message = errors
    i.save(validate:false)

  rescue Exception => e
    i.validation_status = 'INVALID'
    i.validation_message=[e.message]
    i.save(validate:false)
  end

end