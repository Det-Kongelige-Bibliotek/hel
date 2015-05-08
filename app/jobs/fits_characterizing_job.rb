require 'resque'

class FitsCharacterizingJob

  @queue = 'fits_characterizing'

  # Perform fits characterizing of a contentfile
  # @param pid : pid of the contentfile to be characterized
  def self.perform(pid)
    cf = ActiveFedora::Base.find(pid)
    raise ArgumentError.new "#{pid} is not a ContentFile" unless (!cf.nil? && (cf.instance_of? ContentFile))
    name = cf.original_filename.gsub(' ', '_') # Must replace spaces to avoid failure

    tmpfile = Tempfile.new(name)
    tmpfile.binmode # ensures, that non-UTF8 can be written.
    tmpfile.write(cf.datastreams['content'].content)
    tmpfile.rewind

    cf.add_fits_metadata_datastream(tmpfile)
    tmpfile.close
    tmpfile.unlink # deletes the tmp file
  end
end
