require 'resque'

class EmailCreateFileJob

  @queue = :email_create_file

  # Create ContentFile object and attach them to the related Instance
  # @param pathname: the complete path of the folder or file for which a Instance should be created
  # @param instance: the ID of the associated Instance
  def self.perform(pathname, instance_id)

    instance = Instance.find(instance_id)

    if !pathname.nil?
      abs_path = pathname.to_s
      c = ContentFile.new
      f = File.new(abs_path)
      c.add_file(f)
      c.instance = instance
      fail "File could not be added! #{c.errors.messages}" unless c.save
    end
  end
end
