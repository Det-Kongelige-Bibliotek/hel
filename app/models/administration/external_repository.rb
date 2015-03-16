require 'open3'

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
    attribute :base_dir
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


   def clone
     cmd = "git clone #{self.url} #{self.base_dir}; cd #{self.base_dir}; git fetch; git checkout #{self.branch}"
     success = false
     Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
       while line = stdout.gets
         self.add_sync_message(line)
       end
       self.add_sync_message(stderr.read)
       exit_status = wait_thr.value
       success = exit_status.success?
     end
     success
   end

    def update
      cmd = "cd #{self.base_dir};git checkout -f #{self.branch};git pull"
      success = false
      Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
        while line = stdout.gets
          self.add_sync_message(line)
        end
        self.add_sync_message(stderr.read)
        exit_status = wait_thr.value
        success = exit_status.success?
      end
      success
    end

    def push
      cmd = "cd #{self.base_dir};git checkout #{self.branch};git commit -a -m'commit from valhal'; git push --force"
      success = false
      Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
        while line = stdout.gets
          self.add_sync_message(line)
        end
        self.add_sync_message(stderr.read)
        exit_status = wait_thr.value
        success = exit_status.success?
      end
      success
    end
  end
end