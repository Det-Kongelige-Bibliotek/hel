# -*- encoding : utf-8 -*-
module Concerns
  # FITS characterizing tools
  module FitsCharacterizing
    extend ActiveSupport::Concern

    included do
      has_metadata :name => 'fitsMetadata', :type => ActiveFedora::OmDatastream

      #function for extracting FITS metadata from the file data associated with this GenericFile
      #and storing the XML produced as a datastream on the GenericFile Fedora object.
      #If something goes wrong with the file extraction, the RuntimeError is caught, logged and the function
      #will return allowing normal processing of the GenericFile to continue
      def add_fits_metadata_datastream(file)
        logger.info 'Characterizing file using FITS tool'
        begin
          fits_meta_data = Hydra::FileCharacterization.characterize(file, self.original_filename, :fits)
        rescue Hydra::FileCharacterization::ToolNotFoundError => tnfe
          logger.error tnfe.to_s
          logger.error 'Tool for extracting FITS metadata not found, check FITS_HOME environment variable is set and valid installation of fits is present'
          logger.info 'Continuing with normal processing...'
          return
        rescue RuntimeError => re
          logger.error 'Something went wrong with extraction of file metadata using FITS'
          logger.error re.to_s
          logger.info 'Continuing with normal processing...'
          if re.to_s.include? "command not found" #if for some reason the fits command cannot be run from the shell, this hack will get round it
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

        # If datastream already exists, then set it
        self.fitsMetadata.content = fits_meta_data
        self.save
      end
    end
  end
end