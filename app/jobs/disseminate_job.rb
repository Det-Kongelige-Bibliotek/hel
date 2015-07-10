class DisseminateJob
  @queue = 'dissemination'

  def self.perform(instance_id)
    i = Instance.where(id: instance_id)
    i.disseminate
  end

end