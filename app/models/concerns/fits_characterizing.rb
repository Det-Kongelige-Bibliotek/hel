# -*- encoding : utf-8 -*-

module Concerns
  # FITS characterizing tools
  module FitsCharacterizing
    extend ActiveSupport::Concern

    included do
     contains 'fitsMetadata'

      #function for extracting FITS metadata from the file data associated with this GenericFile
      #and storing the XML produced as a datastream on the GenericFile Fedora object.
      #If something goes wrong with the file extraction, the RuntimeError is caught, logged and the function
      #will return allowing normal processing of the GenericFile to continue
      def add_fits_metadata_datastream(file)
        logger.info 'Characterizing file using FITS tool'
        begin
          fits_meta_data = Hydra::FileCharacterization.characterize(file, self.original_filename.gsub(' ', '_'), :fits)
        rescue Hydra::FileCharacterization::ToolNotFoundError => tnfe
          logger.error tnfe.to_s
          logger.error 'Tool for extracting FITS metadata not found, check FITS_HOME environment variable is set and valid installation of fits is present'
          logger.info 'Continuing with normal processing...'
          return
        rescue RuntimeError => re
          logger.error 'Something went wrong with extraction of file metadata using FITS'
          logger.error re.to_s
          logger.info 'Continuing with normal processing...'
          if re.to_s.include? "not found" #if for some reason the fits command cannot be run from the shell, this hack will get round it
            fits_home = `locate fits.sh`.rstrip
            `export FITS_HOME=#{fits_home}`
            stdin, stdout, stderr = Open3.popen3("#{fits_home} -i #{file.path}")
            fits_meta_data = String.new
            stdout.each_line { |line| fits_meta_data.concat(line) }
          else
            return
          end
        end

        # Ensure UTF8 encoding
        fits_meta_data = fits_meta_data.encode(Encoding::UTF_8)

        xml = Nokogiri::XML.parse(fits_meta_data) { |config| config.strict }

        # If datastream already exists, then set it
        self.fitsMetadata.content = fits_meta_data

        self.format_name = xml.xpath(XPATH_FORMAT_NAME, NAMESPACE).first.to_s unless xml.xpath(XPATH_FORMAT_NAME, NAMESPACE).empty?
        self.format_mimetype = xml.xpath(XPATH_FORMAT_MIMETYPE, NAMESPACE).first.to_s unless xml.xpath(XPATH_FORMAT_MIMETYPE, NAMESPACE).empty?
        self.format_version = xml.xpath(XPATH_FORMAT_VERSION, NAMESPACE).first.to_s unless xml.xpath(XPATH_FORMAT_VERSION, NAMESPACE).empty?
        self.format_pronom_id = xml.xpath(XPATH_FORMAT_PRONOM_ID, NAMESPACE).first.to_s unless xml.xpath(XPATH_FORMAT_PRONOM_ID, NAMESPACE).empty?
        self.format_pronom_id = 'unknown' unless self.format_pronom_id

        self.save
      end

      XPATH_FORMAT_NAME = 'fits:fits/fits:identification/fits:identity/@format'
      XPATH_FORMAT_MIMETYPE = 'fits:fits/fits:identification/fits:identity/@mimetype'
      XPATH_FORMAT_PRONOM_ID = 'fits:fits/fits:identification/fits:identity/fits:externalIdentifier/text()'
      XPATH_FORMAT_VERSION = 'fits:fits/fits:identification/fits:identity/fits:version/text()'
      NAMESPACE={'fits' => 'http://hul.harvard.edu/ois/xml/ns/fits/fits_output'}
    end
  end
end
