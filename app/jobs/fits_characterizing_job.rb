require 'resque'

class FitsCharacterizingJob

  @queue = 'fits_characterizing'

  # Perform fits characterizing of a contentfile
  # @param pid : pid of the contentfile to be characterized
  def self.perform(pid)
    cf = ActiveFedora::Base.find(pid)
    raise ArgumentError.new "#{pid} is not a ContentFile" unless cf.instance_of? ContentFile
    tmpfile = Tempfile.new(cf.original_filename)
    tmpfile.binmode # ensures, that non-UTF8 can be written.
    tmpfile.write(cf.datastreams['content'].content)
    tmpfile.rewind
    cf.add_fits_metadata_datastream(tmpfile)
    tmpfile.close
  end
end
