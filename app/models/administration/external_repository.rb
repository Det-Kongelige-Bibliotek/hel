module Administration
  class ExternalRepository < OhmModelWrapper
    attribute :name
    attribute :type
    attribute :url
    attribute :branch
    attribute :activity
    attribute :sync_method
    attribute :sync_status
    attribute :sync_date
    list :sync_message, Administration::SyncMessage
    unique :name

    def clear_sync_messages
      self.sync_message.each do |msg|
        self.sync_message.delete(msg)
        msg.delete
      end
    end

    def add_sync_message(text)
      msg = Administration::SyncMessage.create(msg: text)
      self.sync_message.push(msg)
    end
  end
end