class DisseminateJob
  @queue = 'dissemination'

  def self.perform(instance_id)
    i = Instance.where(id: instance_id).first
    raise "Instance #{instance_id} not found" unless i.present?
    i.disseminate
  end

end