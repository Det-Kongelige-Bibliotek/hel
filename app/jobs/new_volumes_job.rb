##
# Job that search for new scanned books (containing letters) and creates an ingestjop
# xml files should be placed in #{path}/xml
# at least a pdf file #{path}/#{basename}/#{basename}.pdf" and at least on jpg file should be present before an ingest jop is created
##

require "redis"
require "resque"

class NewVolumesJob

  @PROCESSED_FILES  = "letters:ingest:processed_files"

  @queue = :new_letter_volumes

  def self.before_perform(path)
    Resque.logger.debug "Before perfom of NewVolumesJob"
    #Resque.logger = File.open(File.join("path"))
  end

  def self.perform(path)
    Resque.logger.debug "looking for new xml_file in #{path}/output/xml"
    redis = Redis.new

    if (!Dir.exist?("#{path}/output/xml"))
      raise "XML directory #{path}/output/xml does not exist"
    end

    if (!Dir.exist?("#{path}/output/pdf"))
      raise "PDF directory #{path}/output/xml does not exist"
    end

    Dir.glob("#{path}/output/xml/*.xml").each do |fname|
      basename = File.basename(fname,'.xml')
      Resque.logger.debug "got file #{fname}"
      Resque.logger.debug "got file #{basename}"

      if (redis.hget(@PROCESSED_FILES ,basename).blank?)
        Resque.logger.info "Processing new file #{basename} "
        pdfpath = "#{path}/output/pdf/#{basename}.pdf"
        Resque.logger.debug "looking for pdf-file #{pdfpath}"
        jpgpath = "#{path}/#{basename}"
        Resque.logger.debug "looking for jpg-files in #{jpgpath}"

        # only ingest if pdf file and jpgs exits
        if (File.exist?("#{path}/output/pdf/#{basename}.pdf") && Dir.exist?(jpgpath) && (Dir.glob("#{jpgpath}/*.jpg").length > 0))
          Resque.logger.info "The pdf and at least one jpg file exists lets create a ingest job"
          begin
            Resque.enqueue(LetterVolumeIngest,fname,pdfpath,jpgpath)
            redis.hset(@PROCESSED_FILES ,basename,"processed")
          rescue
            raise "Unable to enque file #{fname} for ingest: #{e.message}"
          end
        end
      end
    end
  end
end
