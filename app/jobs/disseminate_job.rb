class DisseminateJob
  @queue = 'dissemination'

  def self.perform(instance_id)
    i = Instance.where(id: instance_id).first
    raise "Instance #{instance_id} not found" unless i.present?
    Resque.logger.debug "disseminating instance #{instance_id}"
    i.disseminate
  end

end