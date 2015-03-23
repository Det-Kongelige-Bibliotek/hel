require 'resque'

class SendToPreservationJob

  @queue = 'send_to_preservation'

  def self.perform(pid, cascade=true)
    obj = nil
    begin
      obj = ActiveFedora::Base.find(pid)
    rescue ObjectNotFoundError
      raise ArgumentError.new "No object with pid #{pid} found"
    end

    if !obj.respond_to?('is_preservable') || !obj.is_preservable || !obj.respond_to?('initiate_preservation')
      raise ArgumentError.new "Object #{pid} of type #{obj.class.name} is not preservable"
    end

    obj.initiate_preservation(cascade)

    if cascade && obj.respond_to?('can_perform_cascading?') && obj.can_perform_cascading?
      obj.cascading_elements.each do |pib|
        Resque.enqueue(SendToPreservationJob,pib.pid,cascade)
      end
    end

  end
end
